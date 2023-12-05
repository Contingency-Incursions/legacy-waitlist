# frozen_string_literal: true

class CharacterNote < ApplicationRecord
  self.table_name = 'character_note'
  belongs_to :character
  belongs_to :author, class_name: 'Character'
end
