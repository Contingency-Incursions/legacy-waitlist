# frozen_string_literal: true

class Character < ApplicationRecord
  self.table_name = 'character'
  belongs_to :corporation


  has_many :access_tokens
  has_many :accounts, class_name: 'AltCharacter', foreign_key: 'account_id'
  has_many :alts, class_name: 'AltCharacter', foreign_key: 'alt_id'
  has_many :announcements
  has_many :badge_assignments
  has_many :badges, through: :badge_assignments
  has_many :issued_bans, class_name: 'Ban'
  has_many :character_notes
  has_many :authored_notes, class_name: 'CharacterNote', foreign_key: 'author_id'
  has_many :fit_histories
  has_many :fleets, foreign_key: 'boss_id'
  has_many :fleet_activities
  has_many :refresh_tokens
  has_many :current_skills, class_name: 'SkillCurrent'
  has_many :skill_histories
  has_many :waitlist_entries, foreign_key: 'account_id'
  has_many :waitlist_entry_fits
  has_many :wiki_users
  has_many :bans, as: :entity



  has_one :admin
end
