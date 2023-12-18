class InvType < ApplicationRecord
  has_many :dgm_type_attributes, foreign_key: 'typeID'
  has_many :dgm_type_effects, foreign_key: 'typeID'
  belongs_to :inv_group, foreign_key: 'groupID'

  alias_attribute :name, :typeName

  self.primary_key = 'typeID'

  def slot
    if cached_effects.find {|e| e.effectID == 11}.present? # Low Slot
      'low'
    elsif cached_effects.find {|e| e.effectID == 13}.present? # Mid Slot
      'med'
    elsif cached_effects.find {|e| e.effectID == 12}.present? # High Slot
      'high'
    elsif cached_effects.find {|e| e.effectID == 2663}.present? # Rig
      'rig'
    elsif cached_group.categoryID == 18 # Drone
      'drone'
    else
      nil
    end
  end

  def skill_requirements
    requirements = {}
    if self.cached_attributes.select { |a| a.attributeID == InvTypesService::PrimarySkill }.length > 0
      skill = get_skill_req(InvTypesService::PrimarySkill, InvTypesService::PrimarySkillLevel)
      requirements[skill[0].to_i] = skill[1].to_i
    end
    if self.cached_attributes.select { |a| a.attributeID == InvTypesService::SecondarySkill }.length > 0
      skill = get_skill_req(InvTypesService::SecondarySkill, InvTypesService::SecondarySkillLevel)
      requirements[skill[0].to_i] = skill[1].to_i
    end
    if self.cached_attributes.select { |a| a.attributeID == InvTypesService::TertiarySkill }.length > 0
      skill = get_skill_req(InvTypesService::TertiarySkill, InvTypesService::TertiarySkillLevel)
      requirements[skill[0].to_i] = skill[1].to_i
    end
    if self.cached_attributes.select { |a| a.attributeID == InvTypesService::QuaternarySkill }.length > 0
      skill = get_skill_req(InvTypesService::QuaternarySkill, InvTypesService::QuaternarySkillLevel)
      requirements[skill[0].to_i] = skill[1].to_i
    end
    if self.cached_attributes.select { |a| a.attributeID == InvTypesService::QuinarySkill }.length > 0
      skill = get_skill_req(InvTypesService::QuinarySkill, InvTypesService::QuinarySkillLevel)
      requirements[skill[0].to_i] = skill[1].to_i
    end
    if self.cached_attributes.select { |a| a.attributeID == InvTypesService::SenarySkill }.length > 0
      skill = get_skill_req(InvTypesService::SenarySkill, InvTypesService::SenarySkillLevel)
      requirements[skill[0].to_i] = skill[1].to_i
    end
    requirements
  end

  def cached_attributes
    @dgm_type_attributes_cache ||= dgm_type_attributes.to_a
  end

  def cached_group
    @inv_group_cache ||= self.inv_group
  end

  def cached_effects
    @dgm_type_effects_cache ||= dgm_type_effects.to_a
  end

  def is_always_cargo
    cached_group.categoryID == 8 || cached_group.categoryID == 20
  end

  private

  def get_skill_req(skill_attr, skill_level_attr)
    skill = self.cached_attributes.select { |a| a.attributeID == skill_attr }.first
    skill_id = skill.valueFloat.present? ? skill.valueFloat : skill.valueInt
    skill_level = self.cached_attributes.select { |a| a.attributeID == skill_level_attr }.first
    skill_level_value = skill_level.valueFloat.present? ? skill_level.valueFloat : skill_level.valueInt
    [skill_id, skill_level_value]
  end
end
