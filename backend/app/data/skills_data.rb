class SkillsData
  class SkillTiers
    GOLD = 2
    ELITE = 1
    MIN = 0
  end
  class SkillsError < StandardError; end

  class SkillData
    attr_accessor :requirements, :categories, :relevant_skills, :name_lookup, :id_lookup

    def initialize
      @requirements = {}
      @categories = {}
      @relevant_skills = Set.new
      @name_lookup = {}
      @id_lookup = {}
    end
  end
  class SkillResponseSkill
    attr_accessor :skill_id, :trained_skill_level, :active_skill_level
  end

  class SkillResponse
    attr_accessor :skills
  end

  class Skills
    def initialize(skills_hash={})
      @skills_hash = skills_hash
    end

    def get(skill_id)
      @skills_hash[skill_id] || 0
    end
  end

  def self.get_skills_data
    Rails.cache.fetch('skills_data', expires_in: 5.days) do
      skill_data
    end
  end

  def self.load_skills(character_id)
    skills_response = esi_client.get("/v4/characters/#{character_id}/skills/", character_id, ESIClientService::Skills_ReadSkills_v1)
    # Assuming SkillCurrent is an AR model
    last_known_skills_query = SkillCurrent.where(character_id: character_id)
    last_known_skills = Hash[last_known_skills_query.map { |sc| [sc.skill_id, sc.level] }]

    now = Time.now.to_i

    # To be replaced with actual method
    tracked_skills = skill_data.relevant_skills

    result = Hash.new
    skills_response['skills'].each do |skill|
      result[skill['skill_id']] = skill['active_skill_level']

      next unless tracked_skills.include?(skill['skill_id'])

      on_record = last_known_skills[skill['skill_id']]
      if on_record == skill['trained_skill_level']
        next
      end

      ActiveRecord::Base.transaction do
        if on_record
          SkillHistory.create(character_id: character_id, skill_id: skill['skill_id'], old_level: on_record, new_level: skill['trained_skill_level'], logged_at: now)
        elsif !last_known_skills.empty?
          SkillHistory.create(character_id: character_id, skill_id: skill['skill_id'], old_level: 0, new_level: skill['trained_skill_level'], logged_at: now)
        end

        skill_current = SkillCurrent.find_or_initialize_by(character_id: character_id, skill_id: skill.skill_id)
        skill_current.level = skill['trained_skill_level']
        skill_current.save!
      end
    end

    Skills.new(result)
  end

  private

  def self.esi_client
    @esi_client ||= ESIClientService.new
  end

  def self.skill_data
    skill_file = Rails.application.config.skills

    skill_data = SkillData.new

    skill_names_to_map = skill_file['categories'].map {|c,n| n}.flatten.compact.uniq
    skill_names_to_map += skill_file['requirements'].map {|c,n| n.keys}.flatten.compact.uniq
    skill_names_to_map += skill_file['other']
    skill_names_to_map.uniq!
    skill_ids = InvTypesService.ids_of(skill_names_to_map)

    # Building the categories
    skill_file["categories"].each do |category_name, skill_names|
      these_skills = skill_names.map {|name| skill_ids.find {|id| id[:name] == name}[:id]}
      skill_data.categories[category_name] = these_skills

      # And add them to known_skills
      skill_data.relevant_skills.merge(these_skills)
    end

    # Building the requirements
    skill_file["requirements"].each do |ship_name, skills|
      these_skills = {}

      skills.each do |skill_name, tiers|
        min_level = tiers["min"]
        elite_level = tiers["elite"] || min_level
        gold_level = tiers["gold"] || 5
        priority = tiers["priority"] || 1

        skill_id = skill_ids.find {|id| id[:name] == skill_name}[:id]
        these_skills[skill_id] = {
          min: min_level,
          elite: elite_level,
          gold: gold_level,
          priority: priority
        }

        # Add them to known_skills
        skill_data.relevant_skills.add(skill_id)
      end

      skill_data.requirements[ship_name] = these_skills
    end

    # Add "OTHER" skills to the 'relevant_skills' list
    skill_file["other"].each do |skill_name|
      skill_id = skill_ids.find {|id| id[:name] == skill_name}[:id]
      skill_data.relevant_skills.add(skill_id) unless skill_data.relevant_skills.include?(skill_id)
    end

    skills_id = skill_data.relevant_skills.to_a # convert to array
    InvTypesService.names_of(skills_id).each do |id, name|
      skill_data.id_lookup[id] = name
      skill_data.name_lookup[name] = id
    end

    return skill_data
  end
end
