Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

CONN = ActiveRecord::Base.connection

def start
	
  started_at = Time.now.strftime("%Y-%m-%d-%H%M%S")

  puts "updating diagnosis observations that were saved as value_text instead of value_coded..."

  diagnosis_with_value_text_obs = Encounter.find_by_sql(" SELECT * FROM #{Source_db}.obs
WHERE voided = 0 
AND concept_id IN (6542,6543,8345,8346,8347,8348) 
AND value_coded IS NULL
AND value_text IS NOT NULL
ORDER BY value_text")

   count_opd_obs = diagnosis_with_value_text_obs.length

  (diagnosis_with_value_text_obs || []).each  do |patient|

    @date_enrolled = patient.obs_datetime#.strftime("%Y-%m-%d %H:%M")
    @date_created  = Date.today.strftime("%Y-%m-%d %H:%M")
    
    fractures = ["Fractures Clavicle", "Fractures Malleoral", "Fractures Metacarpals", "Fractures Metatarsal", "Fractures Spine", "Fractures Pelvis", "Fractures Femur", "Fractures Humerus", "Fractures Phalanges", "Fractures Radius/ulna", "Fractures Tibia/Fibula", "Open Fracture"]
    
    if fractures.include?(patient.value_text)
      @diagnosis = 'Fracture'
    else
      @diagnosis = patient.value_text
    end

    @bart2_diagnosis = Encounter.find_by_sql("SELECT bart_two_concept_name 
                                              FROM #{Source_db}.concept_name_map
                                              WHERE bart_one_concept_name = '#{@diagnosis}'
                                              ").map(&:bart_two_concept_name).first

    @bart2_diagnosis_concept_id = Encounter.find_by_sql("SELECT concept_id 
                                              FROM #{Source_db}.concept_name
                                              WHERE name = '#{@bart2_diagnosis}'").map(&:concept_id).first

    @bart2_dx_value_coded_name_id = Encounter.find_by_sql("SELECT concept_name_id 
                                              FROM #{Source_db}.concept_name
                                              WHERE concept_id = '#{@bart2_diagnosis_concept_id}'").map(&:concept_name_id).first

		ActiveRecord::Base.connection.execute <<EOF
		  UPDATE #{Source_db}.obs
			SET value_coded = #{@bart2_diagnosis_concept_id}, value_text = NULL, value_coded_name_id = #{@bart2_dx_value_coded_name_id}
			WHERE value_text = '#{patient.value_text}'
			AND person_id = #{patient.person_id}
			AND obs_id = #{patient.obs_id}
EOF

    if fractures.include?(patient.value_text)
      if patient.value_text == "Fractures Clavicle"
        @detailed_pri_dx = "Clavicle"
      elsif patient.value_text == "Fractures Malleoral"
        @detailed_pri_dx = "Malleolar"
      elsif patient.value_text == "Fractures Metacarpals"
        @detailed_pri_dx = "Metacarpal"
      elsif patient.value_text == "Fractures Metatarsal"
        @detailed_pri_dx = "Metatarsal"
      elsif patient.value_text == "Fractures Spine"
        @detailed_pri_dx = "Spine"
      elsif patient.value_text == "Fractures Pelvis"
        @detailed_pri_dx = "Pelvis"
      elsif patient.value_text == "Fractures Femur"
        @detailed_pri_dx = "Femur"
      elsif patient.value_text = "Fractures Humerus"
        @detailed_pri_dx = "Humerus"
      elsif patient.value_text == "Fractures Phalanges"
        @detailed_pri_dx = "Phalanges"
      elsif patient.value_text == "Fractures Radius/ulna"
        @detailed_pri_dx = "Radius/ulna"
      elsif patient.value_text == "Fractures Tibia/Fibula"
        @detailed_pri_dx = "Tibia/Fibula"
      else
      end

      @detailed_diagnosis_concept_id = Encounter.find_by_sql("SELECT concept_id 
                                              FROM #{Source_db}.concept_name
                                              WHERE name = '#{@detailed_pri_dx}'").map(&:concept_id).first

      @detailed_dx_value_coded_name_id = Encounter.find_by_sql("SELECT concept_name_id 
                                              FROM #{Source_db}.concept_name
                                              WHERE concept_id = '#{@detailed_diagnosis_concept_id}'").map(&:concept_name_id).first

      if patient.concept_id = 6542 #this is a primary diagnosis concept_id
        #create detailed primary diagnosis details
		ActiveRecord::Base.connection.execute <<EOF
INSERT INTO #{Source_db}.obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
VALUES (#{patient.person_id}, 8345, #{patient.encounter_id}, '#{patient.obs_datetime}', #{patient.location_id}, #{@detailed_diagnosis_concept_id }, #{@detailed_dx_value_coded_name_id}, #{patient.creator}, '#{@date_created}', (SELECT UUID()));
EOF
      elsif patient.concept_id = 6543 #this is a secondary diagnosis concept_id
        #create detailed secondary diagnosis details
		ActiveRecord::Base.connection.execute <<EOF
INSERT INTO #{Source_db}.obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
VALUES (#{patient.person_id}, 8346, #{patient.encounter_id}, '#{patient.obs_datetime}', #{patient.location_id}, #{@detailed_diagnosis_concept_id }, #{@detailed_dx_value_coded_name_id}, #{patient.creator}, '#{@date_created}', (SELECT UUID()));
EOF
      else
      end
    end

      puts "....................#{count_opd_obs -= 1} records to go"
  end    
  
  puts "Started at : #{Time.now}"

end 

start
