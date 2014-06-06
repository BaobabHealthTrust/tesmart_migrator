Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]


CONN = ActiveRecord::Base.connection

def start
  patients = Encounter.find_by_sql("SELECT patient_id, old_enc_id, regimen_category, encounter_datetime
                                    FROM
                                        bart1_intermediate_bare_bones.give_drugs_encounters
                                    WHERE
                                        pres_drug_name1 IS NULL
                                            AND pres_drug_name2 IS NULL
                                            AND pres_drug_name3 IS NULL
                                            AND pres_drug_name4 IS NULL
                                            AND pres_drug_name5 IS NULL
                                    AND old_enc_id IN (SELECT encounter_id 
                                                       FROM #{Source_db}.encounter 
                                                       WHERE encounter_type = 54 AND voided = 0)")




  puts "#{patients.length} records found"
  count_regimen_obs = patients.length	
  
  (patients || []).each do |patient|
    # raise patient.old_enc_id.to_i.to_yaml
     @regimen_cat_obs = Encounter.find_by_sql("SELECT encounter_id FROM #{Source_db}.obs
                                               WHERE encounter_id = #{patient.old_enc_id}
                                               AND person_id = #{patient.patient_id}
					       AND concept_id = 8375
                                               AND voided = 0")
#raise @regimen_cat_obs.to_yaml    
 if @regimen_cat_obs.blank?
	#raise patient.encounter_datetime.strftime('%Y-%m-%-d %H:%M:%S').to_s
     ActiveRecord::Base.connection.execute <<EOF                                                      
     	INSERT INTO #{Source_db}.obs (person_id, concept_id, encounter_id,  obs_datetime, value_text, creator, date_created, uuid)
       	VALUES (#{patient.patient_id}, 8375, #{patient.old_enc_id}, '#{patient.encounter_datetime}', '#{patient.regimen_category}', 1,'#{Date.today.to_date.strftime('%Y-%m-%d 00:00:00')}', (SELECT UUID()))
EOF
    else
       puts 'already created!'
    end
    puts "working on encounter_id: #{patient.old_enc_id}..............#{count_regimen_obs -= 1} records to go" 
  end
end

start
