class InvMetaType < ApplicationRecord
  has_many :dgm_type_attributes, foreign_key: 'typeID'
  has_many :meta_attributes, -> { where attributeID: 633 }, class_name: 'DgmTypeAttribute', foreign_key: 'typeID'
  self.primary_key = 'typeID'
end
