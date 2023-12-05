# frozen_string_literal: true

class FitHistory < ApplicationRecord
  self.table_name = 'fit_history'
  belongs_to :character
  belongs_to :fitting, foreign_key: 'fit_id'
  belongs_to :implant_set
end
