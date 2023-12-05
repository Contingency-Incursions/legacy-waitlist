# frozen_string_literal: true

class Alliance < ApplicationRecord
  self.table_name = 'alliance'
    has_many :bans, as: :entity
end
