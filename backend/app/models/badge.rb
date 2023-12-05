# frozen_string_literal: true

class Badge < ApplicationRecord
  self.table_name = 'badge'
  has_many :badge_assignments, foreign_key: 'badgeid'
  has_many :characters, through: :badge_assignments
end
