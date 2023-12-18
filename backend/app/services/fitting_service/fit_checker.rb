# frozen_string_literal: true

module FittingService
  class FitChecker
    class FitError < StandardError; end

    attr_accessor :approved, :category, :badges, :fitting, :doctrine_fit, :pilot, :tags, :errors, :analysis

    def initialize
      @approved = true
      @category = nil
      @doctrine_fit = nil
      @tags = []
      @errors = []
      @analysis = nil
      yield self
    end

    class << self
      def check(pilot, fit, badges)
        checker = FittingService::FitChecker.new do |c|
          c.approved = true
          c.category = nil
          c.badges = badges
          c.fitting = fit
          c.doctrine_fit = nil
          c.pilot = pilot
          c.tags = []
          c.errors = []
          c.analysis = nil
        end

        begin
          checker.check_skill_reqs
          checker.check_module_skills
          checker.check_fit
          checker.check_fit_reqs
          checker.check_fit_implants_reqs
          checker.check_logi_implants
          checker.set_category
          checker.add_snowflake_tags
          checker.add_implant_tag
          checker.add_war_tags
          checker.merge_tags
          checker.check_time_in_fleet

          checker.finish
          # rescue => e
          #   raise FitError, e.message
        end
      end

      def validate(fit)
        ids = []
        ids << fit[:hull]
        fit[:modules].each do |id, count|
          ids << id if count > 0
        end

        fit[:cargo].each do |id, count|
          ids << id if count > 0
        end

        ids.uniq!

        types = InvTypesService.load_types(ids, with_groups: true)

        ids.each do |id|
          raise FitError.new('Invalid module') unless types[id].present?
        end

        hull_type = types[fit[:hull]]
        raise FitError.new('Not a ship') unless hull_type.inv_group.categoryID == 6 # Ship
      end
    end

    def finish
      {
        approved: @approved,
        tags: @tags,
        errors: @errors,
        category: @category.present? ? @category : 'Category not assigned',
        analysis: @analysis
      }
    end

    def check_time_in_fleet
      pilot_is_elite = ["ELITE", "ELITE-GOLD", "WEB", "BASTION"].any? { |tag| @tags.include?(tag) }

      has_t2_blaster = @fitting[:modules]["Neutron Blaster Cannon II"].to_i > 0
      has_t2_lasers = @fitting[:modules]["Mega Pulse Laser II"].to_i > 0

      if @fitting[:hull] == 11989 # Oneiros
        if @pilot.time_in_fleet >= (105 * 3600) && !pilot_is_elite
          @tags << "ELITE-HOURS-REACHED"
        end
      elsif [641, 17726].include?(@fitting[:hull]) # Megathron, Apocalypse Navy Issue
        if @pilot.time_in_fleet >= (22 * 3600)
          @tags << "UPGRADE-HOURS-REACHED"
        end
      elsif [28661, 17736, 28659, 17740].include?(@fitting[:hull]) # Kronos, Nightmare, Paladin, Vindicator
        if @pilot.time_in_fleet >= (220 * 3600) && !pilot_is_elite
          @tags << "ELITE-HOURS-REACHED"
        elsif @pilot.time_in_fleet >= (130 * 3600)
          if @fitting[:hull] == "Vindicator"
            unless @badges.include?("WEB")
              @tags << "UPGRADE-HOURS-REACHED"
            end
          elsif !((@fitting[:hull] == 28661 && has_t2_blaster) || (@fitting[:hull] == 28659 && has_t2_lasers)) # Kronos, Paladin
            @tags << "UPGRADE-HOURS-REACHED"
          end
        elsif @pilot.time_in_fleet >= (85 * 3600)
          unless [@fitting[:hull] == 28661, @fitting[:hull] == 28659, has_t2_blaster, has_t2_lasers].any? # Kronos, Paladin
            @tags << "UPGRADE-HOURS-REACHED"
          end
        end
      end

      if ["ELITE-HOURS-REACHED", "UPGRADE-HOURS-REACHED"].any? { |tag| @tags.include?(tag) }
        @approved = false
      end
    end

    def merge_tags
      if @tags.include?("ELITE-FIT")
        if ["WARPSPEED", "HYBRID", "AMULET"].any? { |e| @tags.include?(e) } || @tags.include?("SAVIOR")
          if @tags.include?("ELITE-SKILLS")
            @tags.delete("ELITE-FIT")
            @tags.delete("ELITE-SKILLS")
            if @tags.include?("BASTION-SPECIALIST")
              @tags.delete("BASTION-SPECIALIST")
              @tags << "BASTION"
            elsif @tags.include?("WEB-SPECIALIST")
              @tags.delete("WEB-SPECIALIST")
              @tags << "WEB"
            else
              @tags << "ELITE"
            end
          elsif @tags.include?("GOLD-SKILLS")
            @tags.delete("ELITE-FIT")
            @tags.delete("GOLD-SKILLS")
            @tags << "ELITE-GOLD"
            if @tags.include?("BASTION-SPECIALIST")
              @tags.delete("BASTION-SPECIALIST")
              @tags << "BASTION"
            elsif @tags.include?("WEB-SPECIALIST")
              @tags.delete("WEB-SPECIALIST")
              @tags << "WEB"
            end
          end
        elsif @tags.include?("ANTIGANK")
          # ANTIGANK fleet clutter cleanup
          @tags.delete("ELITE-FIT")
        end
      elsif @tags.include?("STARTER-SKILLS") || @tags.include?("STARTER-FIT")
        @tags.delete("STARTER-FIT")
        @tags.delete("STARTER-SKILLS")
        @tags << "STARTER"
      end
    end

    def add_war_tags
      url = "https://evetools.flightleveltech.co.nz/char_checker/#{@pilot.id}"

      begin
        response = HTTParty.get(url, timeout: 5)
        war_data = response.parsed_response[0]

        @tags << "AT-WAR" if war_data["active_war"]
        @tags << "FACTION-WAR" if war_data["faction_war"]
      rescue StandardError => e
        puts e.message
      end
    end

    def add_implant_tag
      if @doctrine_fit.present?
        set_tag = ImplantService.detect_set(@fitting[:hull], @pilot.implants)
        unless set_tag.nil?
          if set_tag == "SAVIOR"
            @tags << "SAVIOR"
          elsif @doctrine_fit[:name].include?(set_tag.titleize) ||
            (set_tag == "WARPSPEED" && !@doctrine_fit[:name].include?("Amulet")) ||
            @fitting[:hull] == 11989 # Oneiros
            @tags << set_tag
            if ImplantService.detect_slot10(@fitting[:hull], @pilot.implants).nil?
              @tags << "NO-SLOT10"
            end
          end
        end
      end
    end

    def add_snowflake_tags
      if @pilot.access_keys.include?('waitlist-tag:HQ-FC')
        @tags << 'HQ-FC'
      elsif @pilot.access_keys.include?('waitlist-tag:TRAINEE')
        @tags << 'TRAINEE'
      end

      # To save space on the XUP card,
      # don't show these badges for FCs
      if @fitting[:hull] == 33472 # Nestor
        @tags << 'LOGI' if @badges.include?('LOGI')
        @tags << 'RETIRED-LOGI' if @badges.include?('RETIRED-LOGI')
      end

      if @fitting[:hull] == 17740 && @badges.include?('WEB') # Vindicator
        @tags << 'WEB-SPECIALIST'
      end

      if (@fitting[:hull] == 28661 || @fitting[:hull] == 28659) && @badges.include?('BASTION') # Kronos, Paladin
        @tags << 'BASTION-SPECIALIST'
      end
    end

    def set_category
      category = CategoriesData.categorize(@fitting) || 'starter'

      if @tags.include?('STARTER-SKILLS') || @tags.include?('STARTER-FIT')
        if category == 'logi'
          @approved = false
        else
          category = 'starter'
        end
      end

      @category = category
    end

    def check_logi_implants
      if @fitting[:hull] == 33472 && !@pilot.implants.include?(3239) # Nestor, EM-806
        @approved = false
        @tags << 'NO-EM-806'
      end
    end

    def check_fit_implants_reqs
      return unless @doctrine_fit

      set_tag = ImplantService.detect_base_set(@pilot.implants) || ""

      if set_tag != "SAVIOR"
        implants_nok = ""

        if @doctrine_fit[:name].include?("Ascendancy") && set_tag != "WARPSPEED"
          implants_nok = "Ascendancy"
        elsif @doctrine_fit[:name].include?("Amulet") && set_tag != "AMULET"
          implants = [
            20499, # High-grade Amulet Alpha
            20501, # High-grade Amulet Beta
            20503, # High-grade Amulet Delta
            20505, # High-grade Amulet Epsilon
            20507, # High-grade Amulet Gamma
          ]
          implants_nok = "Amulet" unless implants.all? { |implant| @pilot.implants.include?(implant) }
        end
        if implants_nok != ""
          @errors.push("Missing required implants to fly #{implants_nok} fit")
        end
      end
    end

    def check_skill_reqs_tier(tier)
      ship_name = @fitting[:hull_name]
      reqs = SkillsData.skill_data.requirements[ship_name]

      return false unless reqs

      reqs.each do |skill_id, tiers|
        return false if req = tiers[tier] and @pilot.skills.get(skill_id) < req
      end
      true
    end

    def check_skill_reqs
      skill_tier = if check_skill_reqs_tier(:gold)
                     "gold"
                   elsif check_skill_reqs_tier(:elite)
                     "elite"
                   elsif check_skill_reqs_tier(:min)
                     "basic"
                   else
                     "starter"
                   end

      case skill_tier
      when "starter"
        @tags.push "STARTER-SKILLS"
      when "gold"
        @tags.push "GOLD-SKILLS"
      when "elite"
        @tags.push "ELITE-SKILLS"
      else
        # Do nothing
      end

    end

    def check_module_skills
      module_ids = [@fitting[:hull]]
      @fitting[:modules].keys.each do |mod_name|
        module_ids.push mod_name
      end

      types = InvTypesService.load_types(module_ids, with_skill_reqs: true)

      types.each do |type_id, type_data|
        raise FitError if type_data.nil?
        type_data.skill_requirements.each do |skill_id, level|
        end
      end

    end

    def check_fit
      doctrine_fit, diff = FittingService::FitMatch.find_fit(@fitting)
      unless doctrine_fit.nil?
        @doctrine_fit = doctrine_fit

        if @doctrine_fit[:name].include?("Antigank")
          # For ANTIGANK, we consider all upgraded mods actually downgrades, since price is an issue
          diff[:module_downgraded] += diff[:module_upgraded]
          @tags << "ANTIGANK"
        end

        fit_ok = diff[:module_downgraded].empty? && diff[:module_missing].empty?

        unless diff[:cargo_missing].empty? && fit_ok
          @approved = false
        end
        @tags << "STARTER-FIT" if @doctrine_fit[:name].include?("Starter")
        @tags << "ELITE-FIT" if fit_ok && (@doctrine_fit[:name].include?("Elite") || @doctrine_fit[:name].include?("Web Specialist"))

        @analysis = {
          name: @doctrine_fit[:name].dup,
          missing: diff[:module_missing],
          extra: diff[:module_extra],
          downgraded: diff[:module_downgraded],
          cargo_missing: diff[:cargo_missing],
        }
      else
        @approved = false
      end
    end

    def check_fit_reqs
      type_ids = InvTypesService.ids_of(["EM Armor Compensation", "Thermal Armor Compensation", "Explosive Armor Compensation", "Kinetic Armor Compensation",
                                         'Bastion Module I', "Hull Upgrades", "Mechanics"])
      comp_reqs = if @doctrine_fit && (@doctrine_fit[:name].include?("Starter") || @doctrine_fit[:name].include?("Nightmare Basic"))
                    2
                  else
                    4
                  end

      have_comps = [
        @pilot.skills.get(type_ids.find { |id| id[:name] == "EM Armor Compensation" }[:id]),
        @pilot.skills.get(type_ids.find { |id| id[:name] == "Thermal Armor Compensation" }[:id]),
        @pilot.skills.get(type_ids.find { |id| id[:name] == "Kinetic Armor Compensation" }[:id]),
        @pilot.skills.get(type_ids.find { |id| id[:name] == "Explosive Armor Compensation" }[:id]),
      ].compact.min

      if have_comps < comp_reqs
        @errors.push("Missing Armor Compensation skills: level #{comp_reqs} required")
      end

      if @fitting[:modules][type_ids.find { |id| id[:name] == 'Bastion Module I' }[:id]].to_i > 0
        if @pilot.skills.get(type_ids.find { |id| id[:name] == "Hull Upgrades" }[:id]).to_i < 5
          @errors.push('Missing tank skill: Hull Upgrades 5 required')
        end

        if @pilot.skills.get(type_ids.find { |id| id[:name] == "Mechanics" }[:id]).to_i < 4
          @errors.push('Missing tank skill: Mechanics 4 required')
        end
      end
    end
  end
end
