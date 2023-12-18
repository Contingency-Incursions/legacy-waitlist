# frozen_string_literal: true

module Waitlist
  class XupService

    class PilotData
      attr_accessor :implants, :time_in_fleet, :skills, :access_keys, :id
    end

    class << self
      include Authentication
      def get_time_in_fleet(char_id)
        fleet_activity = ActiveRecord::Base.connection.exec_query("select
        hull,
        cast(sum(last_seen - first_seen) as bigint) as seconds
        from fleet_activity fa
        left join alt_character ac on ac.alt_id = fa.character_id
        where ac.account_id = $1 or fa.character_id = $1
        group by hull", 'SQL', [char_id])
        total_time = fleet_activity.sum { |x| x['seconds'] }
        bastion_time = fleet_activity.select { |x| [28659, 28661].include?(x['hull']) }.sum { |x| x['seconds'] }
        {
          total: total_time / 3600,
          bastion: bastion_time / 3600
        }
      end

      def process_xups(account, char_fits, is_alt)
        @authenticated_account = account
        now = Time.now

        raise StandardError.new('No fits supplied') if char_fits.length == 0
        raise StandardError.new('Too many fits') if char_fits.length > 10

        raise StandardError.new('Waitlist is closed') unless Fleet.where(visible: true).count > 0

        char_ids = char_fits.map { |x| x[0] }.uniq

        char_info = {}

        char_ids.each do |char_id|
          authorize_character!(char_id, nil)

          active_bans = BanService.character_bans(char_id)

          active_bans.each do |ban|
            case ban.entity_type
            when 'Character'
              raise StandardError.new('You cannot join fleet as your character is banned.')
            when 'Corporation'
              raise StandardError.new('You cannot join fleet as your corporation is banned.')
            when 'Alliance'
              raise StandardError.new('You cannot join fleet as your alliance is banned.')
            else
              raise StandardError.new('You cannot join the waitlist as you are banned')
            end
          end if active_bans.present?

          time_in_fleet = get_time_in_fleet(char_id)
          implants = ImplantData.get_implants(char_id)
          skills = SkillsData.load_skills(char_id)

          char_info[char_id] = [time_in_fleet, implants, skills]
        end

        pilot_data = {}
        char_info.each do |char_id, char_info|

          pilot_data[char_id] = PilotData.new.tap do |pd|
            pd.implants = char_info[1]
            pd.time_in_fleet = char_info[0][:total]
            pd.skills = char_info[2]
            pd.access_keys = account.access
            pd.id = char_id
          end
        end

        WaitlistEntry.transaction do
          entry = WaitlistEntry.where(account_id: account.id).first
          if entry.nil?
            entry = WaitlistEntry.create(account_id: account.id, joined_at: now)
          end

          if (WaitlistEntryFit.where(entry_id: entry.id).count + char_fits.length) > 10
            raise StandardError.new('Too many fits')
          end

          char_fits.each do |char_id, char_fit|
            char_fit.each do |fit|
              FittingService::FitChecker.validate(fit)
              this_pilot_data = pilot_data[char_id]

              fit_id = dedup_dna(fit[:hull], FittingService::Fitting.to_dna(fit))

              implant_set_id = dedup_implants(this_pilot_data.implants)

              existing_entry = WaitlistEntryFit.joins(:fitting).where(character_id: char_id, 'fitting.hull': fit[:hull]).first

              if existing_entry.present?
                existing_entry.destroy
              end

              badges = Badge.joins(:badge_assignments)
                            .where("badge_assignment.characterid = ?", char_id)
                            .pluck(:name)

              fit_checked = FittingService::FitChecker.check(this_pilot_data, fit, badges)
              if fit_checked[:errors].length > 0
                raise StandardError.new(fit_checked[:errors].first)
              end

              tags = fit_checked[:tags].join(',')
              fit_analysis = fit_checked[:analysis].map{ |f| JSON.generate(f) }

              WaitlistEntryFit.create(character_id: char_id, entry_id: entry.id, fit_id: fit_id, category: fit_checked[:category],
                                      state: fit_checked[:approved] ? 'approved' : 'pending', tags: tags, implant_set_id: implant_set_id,
                                      fit_analysis: fit_analysis, cached_time_in_fleet: this_pilot_data.time_in_fleet,
                                      is_alt: is_alt)

              FitHistory.create(character_id: char_id, fit_id: fit_id, implant_set_id: implant_set_id, logged_at: now)
            end
          end
        end

        Notify.send_event(['waitlist_update'], 'waitlist_update')
        Notify.send_event(['notification'], {message: 'New x-up in waitlist'}, sub_override: 'fleet-events')

      end

      private

      def dedup_dna(hull, dna)
        fitting = Fitting.where(dna: dna).first
        return fitting.id if fitting.present?

        fitting = Fitting.create(dna: dna, hull: hull)

        fitting.id

      end

      def dedup_implants(implants)
        implants = implants.sort
        implant_str = implants.join(':')

        implant_set = ImplantSet.find_by(implants: implant_str)

        return implant_set.id if implant_set.present?

        result = ImplantSet.create(implants: implant_str).id
        result.nil? ? 0 : result
      end

    end
  end
end
