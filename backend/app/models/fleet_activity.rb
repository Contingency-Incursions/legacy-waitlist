# frozen_string_literal: true

class FleetActivity < ApplicationRecord
  self.table_name = 'fleet_activity'
  belongs_to :character
  belongs_to :fleet
end
