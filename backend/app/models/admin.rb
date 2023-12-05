# frozen_string_literal: true

class Admin < ApplicationRecord
  self.primary_key = 'character_id'
  self.table_name = 'admin'
    belongs_to :character
end
