class Concept < ActiveRecord::Base
  set_table_name :concept
  set_primary_key :concept_id
  has_many :observations, :foreign_key => :concept_id, 
    :class_name => 'Observation'

end
