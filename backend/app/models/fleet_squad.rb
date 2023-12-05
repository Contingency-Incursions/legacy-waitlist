# frozen_string_literal: true

class FleetSquad < ApplicationRecord
  self.table_name = 'fleet_squad'
  self.primary_key = ['fleet_id', 'category']
  belongs_to :fleet
end
