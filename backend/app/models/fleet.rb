# frozen_string_literal: true

class Fleet < ApplicationRecord
  self.table_name = 'fleet'
  belongs_to :boss, class_name: 'Character', foreign_key: 'boss_id'

  has_many :fleet_activities
  has_many :fleet_squads, dependent: :delete_all
end
