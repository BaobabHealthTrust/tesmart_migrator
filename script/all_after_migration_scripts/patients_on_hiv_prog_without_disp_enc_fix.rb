Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

CONN = ActiveRecord::Base.connection

def start
  patients = Encounter.find_by_sql(" SELECT p.patient_id, s.state, p.patient_program_id
                                     FROM #{Source_db}.patient_program p
                                       INNER JOIN #{Source_db}.patient_state s ON s.patient_program_id = p.patient_program_id
                                     WHERE p.program_id = 1
                                     AND s.state = 7
                                     AND s.voided = 0
                                     AND p.voided = 0")

  (patients || []).each do |patient|

    patient_treatment_encounter = Encounter.find_by_sql("  SELECT patient_id
                                                            FROM #{Source_db}.encounter
                                                            WHERE patient_id = #{patient.patient_id}
                                                            AND encounter_type = 54 ").map(&:patient_id)

    if patient_treatment_encounter.blank?
      patient_art_encounters = Encounter.find_by_sql(" SELECT patient_id FROM #{Source_db}.encounter
                                          WHERE patient_id = #{patient.patient_id}
                                          AND encounter_type IN (51, 52, 53, 9, 25)
                                          AND voided = 0
                                          GROUP BY patient_id").map(&:patient_id)

      if patient_art_encounters.blank?
         puts"voiding HIV program and states of patient_id: #{patient.patient_id}"

          ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.patient_program
SET voided = 1, 
    voided_by = 1, 
    date_voided = '#{Date.today.to_date.strftime('%Y-%m-%d 00:00:00')}', 
    void_reason = 'Patient does not have any ART encounter'
WHERE patient_id = #{patient.patient_id}
AND patient_program_id = #{patient.patient_program_id}
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.patient_state
SET voided = 1, 
    voided_by = 1, 
    date_voided = '#{Date.today.to_date.strftime('%Y-%m-%d 00:00:00')}', 
    void_reason = 'Patient does not have any ART encounter'
WHERE patient_program_id = #{patient.patient_program_id}
EOF

      else
        puts"updating ON ARVs state to Pre-ART state of patient_id: #{patient.patient_id}"

ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.patient_state
SET state = 1, 
    changed_by = 1, 
    date_changed = '#{Date.today.to_date.strftime('%Y-%m-%d 00:00:00')}'
WHERE patient_program_id = #{patient.patient_program_id}
AND state = 7
EOF
      end
    end

  end
end

start
