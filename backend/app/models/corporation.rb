# frozen_string_literal: true

class Corporation < ApplicationRecord
  self.table_name = 'corporation'
  belongs_to :alliance
  has_many :bans, as: :entity
end
