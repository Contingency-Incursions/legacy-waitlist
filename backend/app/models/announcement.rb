# frozen_string_literal: true

class Announcement < ApplicationRecord
  self.table_name = 'announcement'
  belongs_to :created_by, class_name: 'Character'
end
