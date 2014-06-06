=begin

Creator :     Precious Ulemu Bondwe
Date    :     2013-08-28 
Purpose :     To update all ARV drug_orders whose equivalent_daily_dose is NULL
              the appropriate equivalent_daily_dose. This helps in the calculation of adherence.
=end

Source_db = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

CONN = ActiveRecord::Base.connection

def init_variables
  #set Location first
  current_location_id = Encounter.find_by_sql("SELECT property_value FROM #{Source_db}.global_property
                                               WHERE property = 'current_health_center_id'").map(&:property_value).first
end

def start
  init_variables
  @location = Encounter.find_by_sql("SELECT property_value FROM #{Source_db}.global_property
                                     WHERE property = 'current_health_center_id'").map(&:property_value).first

  current_user = Encounter.find_by_sql("SELECT user_id FROM #{Source_db}.users
                                     WHERE user_id = 1").map(&:user_id).first

  start_date = Date.today.strftime('%Y-%m-%d 23:59:59')

  amount_brought_concept_id = Encounter.find_by_sql("SELECT concept_id FROM #{Source_db}.concept_name
                                          WHERE name = 'AMOUNT OF DRUG BROUGHT TO CLINIC'").map(&:concept_id).first

  adherence_concept_id =  Encounter.find_by_sql("SELECT concept_id FROM #{Source_db}.concept_name
                                      WHERE name = 'WHAT WAS THE PATIENTS ADHERENCE FOR THIS DRUG ORDER'").map(&:concept_id).first

  adherence_encounter_id = Encounter.find_by_sql("SELECT encounter_type_id FROM #{Source_db}.encounter_type
                                      WHERE name = 'ART ADHERENCE'").map(&:encounter_type_id).first

  dispense_concept_id = Encounter.find_by_sql("SELECT concept_id FROM #{Source_db}.concept_name
                                      WHERE name = 'Amount dispensed'").map(&:concept_id).first

  records = DrugOrder.find_by_sql("SELECT t3.person_id person_id,
    t1.drug_inventory_id drug_id,DATE(t3.obs_datetime) visit_date, t1.order_id
    FROM #{Source_db}.drug_order t1 INNER JOIN #{Source_db}.orders t2 ON t2.order_id = t1.order_id 
    INNER JOIN #{Source_db}.obs t3 ON t3.order_id = t2.order_id 
    WHERE t3.concept_id = #{amount_brought_concept_id} 
    AND t3.obs_datetime <= '#{start_date}' AND t2.concept_id <> 916 GROUP BY t3.person_id,
    obs_datetime,t3.obs_id").collect do |record|
      [record.person_id,record.drug_id,record.visit_date, record.order_id]
    end

  (records || []).each do |record|
    adherence = ActiveRecord::Base.connection.select_value <<EOF                   
      SELECT #{Source_db}.adherence_cal(#{record[0]},#{record[1]},'#{record[2]}');                                         
EOF
                                                       
    adherence = adherence.to_i rescue nil
    
    adherence_to_show = 0
    adherence_over_100 = 0
    adherence_below_100 = 0
    over_100_done = false
    below_100_done = false

      drug_adherence = adherence
      if drug_adherence <= 100
        adherence_below_100 = adherence.to_i if adherence_below_100 == 0
        adherence_below_100 = adherence.to_i if drug_adherence <= adherence_below_100
        below_100_done = true
      else  
        adherence_over_100 = adherence.to_i if adherence_over_100 == 0
        adherence_over_100 = adherence.to_i if drug_adherence >= adherence_over_100
        over_100_done = true
      end 

    return if !over_100_done and !below_100_done
    over_100 = 0
    below_100 = 0
    over_100 = adherence_over_100 - 100 if over_100_done
    below_100 = 100 - adherence_below_100 if below_100_done

    if over_100 >= below_100 and over_100_done
      adherence = 100 - (adherence_over_100 - 100)
    else
      adherence = adherence_below_100
    end
    
    puts "#{record[0]},#{record[1]},#{record[2]} ============ #{adherence}"                                         

adh_encounter_id =        ActiveRecord::Base.connection.insert "
INSERT INTO #{Source_db}.encounter (encounter_type, patient_id, provider_id, location_id, encounter_datetime, creator, date_created, uuid)
VALUES (#{adherence_encounter_id}, #{record[0]}, #{current_user}, #{@location}, '#{record[2].to_date.strftime('%Y-%m-%d 00:00:02')}', #{current_user}, (NOW()), (SELECT UUID()))"

    ActiveRecord::Base.connection.execute <<EOF
INSERT INTO #{Source_db}.obs (encounter_id, concept_id, person_id, obs_datetime, creator, date_created, location_id, value_text, order_id, uuid)

VALUES (#{adh_encounter_id}, #{adherence_concept_id}, #{record[0]}, '#{record[2].to_date.strftime('%Y-%m-%d 00:00:02')}', #{current_user}, (NOW()), #{@location}, #{adherence}, #{record[3]}, (SELECT UUID()))
EOF

    puts "............... count #{adherence}"
  end

end


start
