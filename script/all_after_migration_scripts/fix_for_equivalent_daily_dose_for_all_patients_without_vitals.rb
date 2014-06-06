=begin

Creator :     Precious Ulemu Bondwe
Date    :     2013-08-28 
Purpose :     To update all ARV drug_orders whose equivalent_daily_dose is NULL
              the appropriate equivalent_daily_dose. This helps in the calculation of adherence.
=end

Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

CONN = ActiveRecord::Base.connection

def start
  time_started = Time.now
  started_at =  Time.now.strftime("%Y-%m-%d-%H%M%S")

  puts "Starting the process at : #{time_started}"
  $failed_orders = File.open("./migration_output/#{started_at}-Failed_orders_for_equivalent_daily_dose.txt", "w")

  orders = Encounter.find_by_sql(" SELECT 
                do.order_id, do.drug_inventory_id AS drug_id, d.concept_id AS drug_concept_id,
                o.patient_id, o.date_created, p.birthdate,
                TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) AS age, obs.value_text
            FROM #{Source_db}.drug_order do
              INNER JOIN #{Source_db}.orders o ON do.order_id = o.order_id
              INNER JOIN #{Source_db}.drug d ON d.drug_id = do.drug_inventory_id
              INNER JOIN #{Source_db}.arv_drug ad ON ad.drug_id = do.drug_inventory_id
              INNER JOIN #{Source_db}.person p ON p.person_id = o.patient_id AND p.voided = 0
              INNER JOIN #{Source_db}.obs obs ON obs.encounter_id = o.encounter_id AND obs.concept_id = 8375
            WHERE (do.equivalent_daily_dose IS NULL OR do.equivalent_daily_dose = 0)
            ORDER BY drug_id")
  
  count = 0
  total_orders = orders.length

  puts "Drug Orders to Update:==> #{orders.length}"

  orders.each do |order|
        if !order.value_text.blank?
		count += 1
	
		#get regimen category observation
		regimen_id = Encounter.find_by_sql("
		                    SELECT regimen_id FROM #{Source_db}.regimen
                                    WHERE concept_id = #{order.drug_concept_id}
                                    AND regimen_index = '#{order.value_text}' 
                                    ORDER BY min_weight
                                    LIMIT 1").map(&:regimen_id).first

        	if ! regimen_id.blank?
			regimen_drug = Encounter.find_by_sql("
		        	                        SELECT dose, equivalent_daily_dose
		                	                FROM #{Source_db}.regimen_drug_order
                                    			WHERE regimen_id = #{regimen_id} ")
	        	
			update_drug_order(regimen_drug.first.dose, regimen_drug.first.equivalent_daily_dose, order.order_id)
    			puts "working on order: #{order.order_id}"
		else
			regimen_drug = Encounter.find_by_sql("
					    SELECT 
							r.regimen_id, r.concept_id, rdo.drug_inventory_id,
                                  			r.min_weight, r.max_weight, rdo.equivalent_daily_dose,
                                  			rdo.dose, r.regimen_index
	                              	    FROM #{Source_db}.regimen r
        	                        	INNER JOIN #{Source_db}.regimen_drug_order rdo ON rdo.regimen_id = r.regimen_id
                                      			AND r.retired = 0
                                		INNER JOIN #{Source_db}.arv_drug ad ON ad.drug_id = rdo.drug_inventory_id
                              		    WHERE regimen_index = '#{order.value_text}'
                              		    AND (drug_inventory_id = #{order.drug_id})
                              		    ORDER BY min_weight DESC LIMIT 1")
			if !regimen_drug.blank?
			  update_drug_order(regimen_drug.first.dose, regimen_drug.first.equivalent_daily_dose, order.order_id)
        	          puts "working on order: #{order.order_id}"
	        	else
			  regimen_drug = Encounter.find_by_sql("
                                            SELECT 
                                                r.regimen_id, r.concept_id, rdo.drug_inventory_id,
                                                r.min_weight, r.max_weight, rdo.equivalent_daily_dose,
                                                rdo.dose, r.regimen_index
                                            FROM #{Source_db}.regimen r
                                                INNER JOIN #{Source_db}.regimen_drug_order rdo ON rdo.regimen_id = r.regimen_id
                                                        AND r.retired = 0
                                                INNER JOIN #{Source_db}.arv_drug ad ON ad.drug_id = rdo.drug_inventory_id
                                            WHERE regimen_index = '#{order.value_text}'
                                            ORDER BY min_weight DESC LIMIT 1")

			  update_drug_order(regimen_drug.first.dose, regimen_drug.first.equivalent_daily_dose, order.order_id)
                          puts "working on order: #{order.order_id}"
			end
		end
	  else
		regimen_drug = Encounter.find_by_sql(" SELECT r.regimen_id, r.concept_id, rdo.drug_inventory_id,
						              r.min_weight, r.max_weight, rdo.equivalent_daily_dose,
                 					      rdo.dose, r.regimen_index
					FROM #{Source_db}.regimen r
				          INNER JOIN #{Source_db}.regimen_drug_order rdo ON rdo.regimen_id = r.regimen_id
                       				    AND r.retired = 0
				          INNER JOIN #{Source_db}.arv_drug ad ON ad.drug_id = rdo.drug_inventory_id
				        WHERE (drug_inventory_id = #{order.drug_id})
				        ORDER BY min_weight DESC
				        LIMIT 1")
		if !regimen_drug.blank?

	            update_drug_order(regimen_drug.first.dose, regimen_drug.first.equivalent_daily_dose, order.order_id)
               	    puts "working on order: #{order.order_id}"
                else
		   puts "#{order.order_id} failed"
		   $failed_orders << "#{order.order_id} \n"
                end
	  end	
        end
end

def update_drug_order(dose, equivalent_daily_dose, order_id)
	#update the drug orders table
	ActiveRecord::Base.connection.execute <<EOF
	UPDATE #{Source_db}.drug_order
	  SET dose = #{dose},
		equivalent_daily_dose = #{equivalent_daily_dose}
	  WHERE order_id = #{order_id}
EOF
end
start
