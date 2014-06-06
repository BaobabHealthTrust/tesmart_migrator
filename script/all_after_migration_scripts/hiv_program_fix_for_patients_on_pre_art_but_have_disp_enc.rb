Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

CONN = ActiveRecord::Base.connection

def start
  patients = Encounter.find_by_sql("SELECT DISTINCT patient_id from bart1_intermediate_bare_bones.give_drugs_encounters")
  
  (patients || []).each do |patient|
#raise patient.to_yaml
   patient_pre_art_state = Encounter.find_by_sql(" SELECT p.patient_id, s.state, p.patient_program_id
                                     FROM #{Source_db}.patient_program p
                                       INNER JOIN #{Source_db}.patient_state s ON s.patient_program_id = p.patient_program_id
                                     WHERE p.program_id = 1
                                     AND s.state = 1
                                     AND p.patient_id = #{patient.patient_id}
                                     AND DATE(s.date_changed) = '2014-04-26' and s.changed_by = 1
                                     AND s.voided = 0
                                     AND p.voided = 0").map(&:patient_program_id)
    
    if !patient_pre_art_state.blank?
       treatment_encounter = Encounter.find_by_sql("SELECT * FROM #{Source_db}.encounter
                                                    WHERE encounter_type = 54
                                                    AND voided = 0")
       if !treatment_encounter.blank?
         (patient_pre_art_state || [] ).each do |patient_program_id|

	 puts"updating 'Pre-ART' state to 'On ARVs state' of patient_id: #{patient.patient_id}"

ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.patient_state
SET state = 7, 
    changed_by = 1,
    date_changed = '#{Date.today.to_date.strftime('%Y-%m-%d 00:00:00')}'
WHERE patient_program_id = #{patient_program_id}
AND state = 1
EOF
       end
     else
	puts "Patient without any dispensing encounter"
     end
    else
      puts "Patient already 'On ARVs'"
    end                                    
  end

end

start
