Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

CONN = ActiveRecord::Base.connection

def start
  hiv_prog = Encounter.find_by_sql("SELECT program_id FROM #{Source_db}.program WHERE name = 'HIV Program'").map(&:program_id).first

  art_patients = Encounter.find_by_sql("SELECT distinct patient_id, patient_program_id from #{Source_db}.patient_program where program_id = #{hiv_prog} and voided = 0 ")

  (art_patients || []).each do |patient|
    patient_obj = Encounter.find_by_sql("SELECT * FROM #{Source_db}.patient
                                         WHERE patient_id = #{patient.patient_id}")

    enrolled_date = date_antiretrovirals_started(patient) 

    first_dispense = get_first_dispensation(patient.patient_id)


    unless first_dispense.blank?
      if enrolled_date != first_dispense && !enrolled_date.blank?
        puts "change dates"
        first_dispense = first_dispense.to_date if !first_dispense.blank?
        
        correct_start_date = first_dispense.to_date.strftime('%Y-%m-%d 00:00:00')

				latest_program = Encounter.find_by_sql("SELECT patient_program_id FROM #{Source_db}.patient_program
				                                        WHERE program_id = 1
				                                        AND patient_id = #{patient.patient_id}
				                                        AND voided = 0").map(&:patient_program_id).first
				                                        	
				last_state = Encounter.find_by_sql("SELECT patient_state_id FROM #{Source_db}.patient_state
				                                        WHERE patient_program_id = #{latest_program}
				                                        AND state = 7").map(&:patient_state_id).first

			unless last_state.blank?
			
        ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.patient_program
SET date_enrolled = '#{first_dispense.strftime('%Y-%m-%d 00:00:00')}'
WHERE patient_program_id = #{latest_program}
EOF

        ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.patient_state
SET start_date = '#{first_dispense.to_date.strftime('%Y-%m-%d 00:00:00')}',
date_created = '#{first_dispense.to_date.strftime('%Y-%m-%d 00:00:00')}'
WHERE patient_state_id = #{last_state}
EOF

				end
				enrolled_date = enrolled_date.to_date if !enrolled_date.blank?
				correct_start_date = correct_start_date.to_date if !correct_start_date.blank?
        puts">>>>>>>#{patient.patient_id}....From: #{enrolled_date}......To: #{correct_start_date.to_date}........."
      end


    end

end

end

def get_first_dispensation(patient_id)
		arv_concept       =  Encounter.find_by_sql("SELECT concept_id FROM #{Source_db}.concept_name
                                                WHERE name = 'ANTIRETROVIRAL DRUGS'").map(&:concept_id).first

		arv_drug_concepts =   Encounter.find_by_sql("SELECT * FROM #{Source_db}.concept_set
                                                WHERE concept_set = #{arv_concept}").collect{|x| x.concept_id.to_i}

	  arv_drugs =   Encounter.find_by_sql("SELECT * FROM #{Source_db}.drug
                                                WHERE concept_id IN (#{arv_drug_concepts.join(',')})").collect{|x| x.drug_id}
		
		#arv_drug_concepts





 # arv_drug_concepts =  MedicationService.arv_drugs.collect{|x| x.concept_id}

 # arv_drugs = Drug.find(:all, :conditions => ["concept_id in (?)", arv_drug_concepts]).collect{|x| x.drug_id}

  dispense_conc = Encounter.find_by_sql("SELECT concept_id FROM #{Source_db}.concept_name
                                         WHERE name = 'Amount Dispensed'").map(&:concept_id).first

  dispense_obs = Encounter.find_by_sql("SELECT min(obs_datetime) as obs_datetime from #{Source_db}.obs where person_id = #{patient_id}
                                        AND concept_id = #{dispense_conc} and value_drug in (#{arv_drugs.join(',')})")

  return dispense_obs.first.obs_datetime rescue nil

end

def date_antiretrovirals_started(patient)

  concept_id = Encounter.find_by_sql("SELECT concept_id FROM #{Source_db}.concept_name
                                      WHERE name = 'ART START DATE'").map(&:concept_id).first
  
  start_date = Encounter.find_by_sql("SELECT value_datetime FROM obs
                                      WHERE concept_id = #{concept_id}
                                      AND person_id = #{patient.patient_id} ").map(&:value_datetime).first rescue ""

  if start_date.blank? || start_date == ""
    concept_id = Encounter.find_by_sql("SELECT concept_id FROM #{Source_db}.concept_name
                                        WHERE name = 'Date antiretrovirals started'").map(&:concept_id).first
      
    start_date = Encounter.find_by_sql("SELECT value_text FROM #{Source_db}.obs
                                        WHERE concept_id = #{concept_id}
                                        AND person_id = #{patient.patient_id}").map(&:value_text).first  rescue ""    

    art_start_date = start_date
    if art_start_date.blank? || art_start_date == ""
      start_date = ActiveRecord::Base.connection.select_value "
        SELECT earliest_start_date FROM #{Source_db}.earliest_start_date
        WHERE patient_id = #{patient.patient_id} LIMIT 1"
    end
  end

  start_date.to_date rescue nil
end

start
