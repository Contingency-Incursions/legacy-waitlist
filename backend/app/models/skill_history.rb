# frozen_string_literal: true

class SkillHistory < ApplicationRecord
  self.table_name = 'skill_history'
  belongs_to :character
end
