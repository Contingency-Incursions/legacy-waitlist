class InvGroup < ApplicationRecord
  has_many :inv_types, foreign_key: 'groupID'

  self.primary_key = 'groupID'
end
