# frozen_string_literal: true

class BadgeAssignment < ApplicationRecord
  self.table_name = 'badge_assignment'
  self.primary_key = [:characterid, :badgeid]
  belongs_to :character, foreign_key: 'characterid'
  belongs_to :badge, foreign_key: 'badgeid'
end
