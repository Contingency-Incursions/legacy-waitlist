# frozen_string_literal: true

class BadgeAssignment < ApplicationRecord
  self.table_name = 'badge_assignment'
  self.primary_key = [:characterid, :badgeid]
  belongs_to :character, foreign_key: 'characterid'
  belongs_to :badge, foreign_key: 'badgeid'
  belongs_to :granted_by, class_name: 'Character', foreign_key: 'grantedbyid'

  alias_attribute :badge_id, :badgeid
  alias_attribute :granted_at, :grantedat

end
