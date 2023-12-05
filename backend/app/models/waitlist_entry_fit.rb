# frozen_string_literal: true

class WaitlistEntryFit < ApplicationRecord
  self.table_name = 'waitlist_entry_fit'
  belongs_to :character
  belongs_to :entry, class_name: 'WaitlistEntry', foreign_key: 'entry_id'
  belongs_to :fitting, foreign_key: 'fit_id'
  belongs_to :implant_set
end
