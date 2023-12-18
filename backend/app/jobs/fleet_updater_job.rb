# frozen_string_literal: true

class FleetUpdaterJob < ApplicationJob
  def perform(*args)
    esi_client = ESIClientService.new
    fleets = Fleet.where('error_count < ?', 10)
    fleets.each do |fleet|
      begin
      fleet_members = esi_client.get("/v1/fleets/#{fleet.id}/members", fleet.boss_id, ESIClientService::Fleets_ReadFleet_v1)
      rescue ESIError, NoTokenError => e
        if e.message == 'MissingScope' or e.message == 'NoToken' or e.code == 403 or e.instance_of?(NoTokenError)
          fleet.update(error_count: 10)
          next
          # TODO Sentry error
        elsif e.code == 404
          fleet.update(error_count: (fleet.error_count + 1))
          next
        elsif e.code == 500
          # CCP error
          next
        else
          fleet.update(error_count: (fleet.error_count + 1))
          # Sentry error
          next
        end
      rescue => e
        fleet.update(error_count: (fleet.error_count + 1))
        # Sentry error
        next
      end

      member_ids = fleet_members.map {|m| m['character_id']}
      now = Time.now

      characters = Character.where(id: member_ids).index_by(&:id)

      member_ids.each do |member_id|
        char = characters[member_id]

        if char.present?
          char.update(last_seen: now)
        else
          char_data = esi_client.get("/v5/characters/#{member_id}", fleet.boss_id, ESIClientService::PublicData)

          char = Character.create(id: member_id, name: char_data['name'], last_seen: now)
          characters[member_id] = char
        end

      end

      waitlist_changed = false

      waitlist = WaitlistEntryFit.joins(:entry).includes(:entry).all.index_by(&:character_id)

      member_ids.each do |id|
        if waitlist[id].present?
          waitlist_changed = true
          entry = waitlist[id]
          if entry.is_alt
            WaitlistEntryFit.where(character_id: entry.character_id).each(&:destroy)
          else
            WaitlistEntryFit.where(entry_id: entry.entry_id, is_alt: false).each(&:destroy)
          end
        end
      end

      WaitlistEntry.where.not(id: WaitlistEntryFit.all.pluck(:entry_id)).each(&:destroy)

      boss_system_changed = false
      fleet_comp_changed = false

      ActiveRecord::Base.transaction do
        in_fleet = FleetActivity.where(fleet_id: fleet.id, has_left: false).index_by(&:character_id)

        # Checking if the number of pilots reported is sufficient as per the minimum pilots required for fleet updater in the config.
        min_pilots_in_fleet = fleet_members.size >= ENV['MIN_IN_FLEET'].to_i

        fleet_members.each do |member|
          is_boss = member['character_id'] == fleet.boss_id

          if is_boss && (!fleet.boss_system_id || fleet.boss_system_id != member['solar_system_id'])
            Fleet.where(id: fleet_id).update_all(boss_system_id: member['solar_system_id'])
            boss_system_changed = true
          end

          if min_pilots_in_fleet
            insert_record = false

            in_db = in_fleet[member['character_id']]

            if in_db
              if in_db.hull == member['ship_type_id'] && in_db.is_boss == is_boss
                if in_db.last_seen < (now - 60.seconds).to_i
                  in_db.update(last_seen: now)
                  fleet_comp_changed = true
                end
              else
                in_db.update(has_left: true, last_seen: now)
                insert_record = true
              end
            else
              insert_record = true
            end

            if insert_record
              FleetActivity.create(character_id: member['character_id'], fleet_id: fleet.id,
                                   first_seen: now, last_seen: now, is_boss: is_boss, hull: member['ship_type_id'], has_left: false)
              fleet_comp_changed = true
            end
          end
        end

        members_map = fleet_members.index_by {|m| m['character_id']}

        in_fleet.each do |id, pilot|
          unless members_map.key?(id)
            pilot.update(has_left: true)
            fleet_comp_changed = true
          end
        end
      end

      if waitlist_changed
        Notify.send_event(['waitlist_update'], 'waitlist_update')
      end

      if fleet_comp_changed
        Notify.send_event(['fleet_comp'], {id: fleet.id})
      end

      if boss_system_changed
        Notify.send_event(['fleet_settings'], {id: fleet.id})
      end


    end
  end
end
