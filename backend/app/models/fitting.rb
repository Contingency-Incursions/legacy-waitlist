# frozen_string_literal: true

class Fitting < ApplicationRecord
  self.table_name = 'fitting'
  has_many :fit_histories, foreign_key: 'fit_id'
  has_many :waitlist_entry_fits, foreign_key: 'fit_id'
end
