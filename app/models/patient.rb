class Patient < ActiveRecord::Base
  has_one :guardian, :foreign_key => :patient_id, :class_name => 'Guardian'
end
