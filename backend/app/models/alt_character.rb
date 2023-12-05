# frozen_string_literal: true

class AltCharacter < ApplicationRecord
  self.table_name = 'alt_character'
  self.primary_key = ['account_id', 'alt_id']
  belongs_to :account, class_name: 'Character', foreign_key: 'account_id'
  belongs_to :alt, class_name: 'Character', foreign_key: 'alt_id'

end
