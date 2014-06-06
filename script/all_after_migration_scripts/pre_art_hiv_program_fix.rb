Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

CONN = ActiveRecord::Base.connection

def start
  patients = Encounter.find_by_sql(" SELECT patient_id FROM #{Source_db}.encounter
                                          WHERE patient_id NOT IN ( SELECT patient_id
                                                                    FROM #{Source_db}.patient_program
                                                                    WHERE program_id = 1
                                                                    AND voided = 0)
                                          AND encounter_type IN (52, 53, 25, 54)
                                          AND voided = 0
                                          GROUP BY patient_id").map(&:patient_id)

  (patients || []).each do |patient|

    patient_first_encounter_date = Encounter.find_by_sql("  SELECT encounter_datetime
                                                            FROM #{Source_db}.encounter
                                                            WHERE patient_id = #{patient}
                                                            AND encounter_type IN (52, 53, 25, 54)
                                                            ORDER BY encounter_datetime ASC
                                                            LIMIT 1 ").map(&:encounter_datetime)

    if !patient_first_encounter_date.blank?
        ActiveRecord::Base.connection.execute <<EOF                                                      
INSERT INTO #{Source_db}.patient_program (patient_id, program_id, date_enrolled, date_created, creator, uuid)
VALUES (#{patient}, 1, '#{patient_first_encounter_date}', '#{Date.today.to_date.strftime('%Y-%m-%d 00:00:00')}', 1, (SELECT UUID()))
EOF

      @patient_program_id = Encounter.find_by_sql("SELECT patient_program_id
                                                        FROM #{Source_db}.patient_program
                                                        WHERE patient_id = #{patient}
                                                        AND program_id = 1 ").map(&:patient_program_id)
    end

    if @patient_program_id
        ActiveRecord::Base.connection.execute <<EOF                                                      
INSERT INTO #{Source_db}.patient_state (patient_program_id, state, start_date, date_created, creator, uuid)
VALUES (#{@patient_program_id}, 1, '#{patient_first_encounter_date}', '#{Date.today.to_date.strftime('%Y-%m-%d 00:00:00')}', 1, (SELECT UUID()))
EOF
   end
         puts"working on patient_id: #{patient}"                                   
  end
end

start
