# frozen_string_literal: true

class WikiUser < ApplicationRecord
  self.table_name = 'wiki_user'
  self.primary_key = 'character_id'
  belongs_to :character
end
