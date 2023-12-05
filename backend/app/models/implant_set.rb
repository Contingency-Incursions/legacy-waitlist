# frozen_string_literal: true

class ImplantSet < ApplicationRecord
  self.table_name = 'implant_set'
  has_many :fit_histories
  has_many :waitlist_entry_fits
end
