class Encounter < ActiveRecord::Base
	set_table_name :encounter
	set_primary_key :encounter_id
	has_many :observations, :dependent => :destroy, :conditions => {:voided => 0}
	has_many :orders, :foreign_key => :encounter_id
	has_one :enc_type, :foreign_key => :encounter_type_id
	belongs_to :user, :foreign_key => :user_id
	belongs_to :patient, :foreign_key => :patient_id


  def name
    EncounterType.find(self.encounter_type).name
  end

end
