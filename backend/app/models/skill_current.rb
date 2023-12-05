# frozen_string_literal: true

class SkillCurrent < ApplicationRecord
  self.table_name = 'skill_current'
  self.primary_key = ['character_id', 'skill_id']
  belongs_to :character
end
