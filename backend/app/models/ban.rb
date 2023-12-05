# frozen_string_literal: true

class Ban < ApplicationRecord
  self.table_name = 'ban'
  belongs_to :issued_by, class_name: 'Character'
  belongs_to :entity, polymorphic: true
end
