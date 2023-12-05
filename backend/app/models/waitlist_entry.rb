# frozen_string_literal: true

class WaitlistEntry < ApplicationRecord
  self.table_name = 'waitlist_entry'
  belongs_to :account, class_name: 'Character', foreign_key: 'account_id'
  has_many :waitlist_entry_fits, foreign_key: 'entry_id'
end
