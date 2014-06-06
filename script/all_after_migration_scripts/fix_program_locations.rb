Source_db = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

CONN = ActiveRecord::Base.connection


def update_locations
  current_location_id = Encounter.find_by_sql("SELECT property_value FROM #{Source_db}.global_property
                                               WHERE property = 'current_health_center_id'").map(&:property_value).first

          ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.patient_program
SET location_id = #{current_location_id}
EOF

	fix_retired_drug
end

def fix_retired_drug

	retired =  DrugOrder.find_by_sql("SELECT * FROM #{Source_db}.drug_order
	                                  WHERE drug_inventory_id IN (614, 1610)")
	
	retired.each do |drug_order|
	
		dispense_date = Encounter.find_by_sql("SELECT start_date FROM #{Source_db}.orders
		                                  WHERE order_id = #{drug_order.order_id}").map(&:start_date).first.to_date.year


    dob = Encounter.find_by_sql("SELECT p.birthdate FROM #{Source_db}.orders o
                                    INNER JOIN #{Source_db}.person p ON p.person_id = o.patient_id
		                               WHERE o.order_id = #{drug_order.order_id}").map(&:birthdate).first.to_date.year
	
		unless dob.nil?

			age = dispense_date - dob
			dispense_obs = Observation.find_by_sql("SELECT * FROM #{Source_db}.obs
			                                        WHERE order_id = #{drug_order.order_id}
			                                        AND value_drug = 614")

			if age < 14
				new_drug_inventory_id = Encounter.find_by_sql("SELECT drug_id FROM #{Source_db}.drug
				                                               WHERE name = 'AZT/3TC/NVP (60/30/50mg tablet)'").map(&:drug_id).first
			else
				new_drug_inventory_id = Encounter.find_by_sql("SELECT drug_id FROM #{Source_db}.drug
				                                               WHERE name = 'AZT/3TC/NVP (300/150/200mg tablet)'").map(&:drug_id).first
			end
				
        ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.drug_order
SET drug_inventory_id = #{new_drug_inventory_id}
WHERE order_id = #{drug_order.order_id}
AND drug_inventory_id = 614
EOF

			dispense_obs.each do |obs|
			
				if age < 14
					obs_value_drug = Encounter.find_by_sql("SELECT drug_id FROM #{Source_db}.drug
				                                          WHERE name = 'AZT/3TC/NVP (60/30/50mg tablet)'").map(&:drug_id).first
				else
					obs_value_drug = Encounter.find_by_sql("SELECT drug_id FROM #{Source_db}.drug
				                                          WHERE name = 'AZT/3TC/NVP (300/150/200mg tablet)'").map(&:drug_id).first		
				end

        ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.obs
SET value_drug = #{obs_value_drug}
WHERE order_id = #{drug_order.order_id}
AND value_drug = 614
AND concept_id = #{obs.concept_id}
EOF
			
			end
			puts "working on order_id.....#{drug_order.order_id}...."
		end
	end 

end

update_locations
