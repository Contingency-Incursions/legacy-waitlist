# frozen_string_literal: true

class AccessToken < ApplicationRecord
  self.primary_key = 'character_id'
  self.table_name = 'access_token'
  belongs_to :character
end
