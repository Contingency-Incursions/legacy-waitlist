# frozen_string_literal: true

class Admin < ApplicationRecord
  self.primary_key = 'character_id'
  self.table_name = 'admin'
  belongs_to :character
  belongs_to :granted_by, class_name: 'Character', foreign_key: 'granted_by_id'
end
