class VisitEncounter < ActiveRecord::Base
  set_table_name :visit_encounters
  set_primary_key :id
  has_many :first_visit_encounters, :foreign_key => :visit_encounter_id,
           :dependent => :destroy, :class_name => 'FirstVisitEncounter'
  has_many :give_drugs_encounters, :foreign_key => :visit_encounter_id,
           :dependent => :destroy, :class_name => 'GiveDrugsEncounter'
  has_many :hiv_staging_encounters, :foreign_key => :visit_encounter_id,
           :dependent => :destroy, :class_name => 'HivStagingEncounter'
  has_many :outcome_encounters, :foreign_key => :visit_encounter_id,
           :dependent => :destroy, :class_name => 'OutcomeEncounter'
  has_many :pre_art_encounters, :foreign_key => :visit_encounter_id,
           :dependent => :destroy, :class_name => 'PreArtVisitEncounter'
  has_many :art_encounters, :foreign_key => :visit_encounter_id,
           :dependent => :destroy, :class_name => 'ArtVisitEncounter'
  has_many :vitals_encounters, :foreign_key => :visit_encounter_id,
           :dependent => :destroy, :class_name => 'VitalsEncounter'

end
