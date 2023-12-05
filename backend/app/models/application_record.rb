class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  establish_connection :primary
end
