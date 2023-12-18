# frozen_string_literal: true

class Ban < ApplicationRecord
  self.table_name = 'ban'
  belongs_to :issued_by, class_name: 'Character', foreign_key: 'issued_by'
  belongs_to :entity, polymorphic: true, optional: true
end
