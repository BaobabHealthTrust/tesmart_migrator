class Patient < ActiveRecord::Base
  has_one :guardian, :foreign_key => :patient_id, :class_name => 'Guardian'
  set_primary_key :patient_id
end
