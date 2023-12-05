# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  self.primary_key = 'character_id'
  self.table_name = 'refresh_token'
  belongs_to :character
end
