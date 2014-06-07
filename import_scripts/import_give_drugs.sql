# This procedure imports patients hiv_staging encounters from intermediate tables to ART2 OpenMRS database
# ASSUMPTION
# ==========
# The assumption here is your source database name is `bart1_intermediate_bare_bones`
# and the destination any name you prefer.
# This has been necessary because there seems to be no way to use dynamic database 
# names in procedures yet

# The default DELIMITER is disabled to avoid conflicting with our scripts
DELIMITER $$

# Check if a similar procedure exists and drop it so we can start from a clean slate
DROP PROCEDURE IF EXISTS `proc_import_give_drugs`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_import_give_drugs`(
IN in_patient_id INT(11)
)

BEGIN
    
    # Declare condition for exiting loop
    DECLARE done INT DEFAULT FALSE;

    DECLARE  id int(11);
    DECLARE  visit_encounter_id int(11);
    DECLARE  old_enc_id int(11);
    DECLARE  patient_id int(11);
    DECLARE  pres_drug_name1 varchar(255);
    DECLARE  pres_dosage1 varchar(255);
    DECLARE  pres_frequency1 varchar(255);
    DECLARE  pres_drug_name2 varchar(255);
    DECLARE  pres_dosage2 varchar(255);
    DECLARE  pres_frequency2 varchar(255);
    DECLARE  pres_drug_name3 varchar(255);
    DECLARE  pres_dosage3 varchar(255);
    DECLARE  pres_frequency3 varchar(255);
    DECLARE  pres_drug_name4 varchar(255);
    DECLARE  pres_dosage4 varchar(255);
    DECLARE  pres_frequency4 varchar(255);
    DECLARE  pres_drug_name5 varchar(255);
    DECLARE  pres_dosage5 varchar(255);
    DECLARE  pres_frequency5 varchar(255);
    DECLARE  prescription_duration varchar(255);
    DECLARE  dispensed_drug_name1 varchar(255);
    DECLARE  dispensed_dosage1 varchar(255);
    DECLARE  dispensed_quantity1 int(11);
    DECLARE  dispensed_drug_name2 varchar(255);
    DECLARE  dispensed_dosage2 varchar(255);
    DECLARE  dispensed_quantity2 int(11);
    DECLARE  dispensed_drug_name3 varchar(255);
    DECLARE  dispensed_dosage3 varchar(255);
    DECLARE  dispensed_quantity3 int(11);
    DECLARE  dispensed_drug_name4 varchar(255);
    DECLARE  dispensed_dosage4 varchar(255);
    DECLARE  dispensed_quantity4 int(11);
    DECLARE  dispensed_drug_name5 varchar(255);
    DECLARE  dispensed_dosage5 varchar(255);
    DECLARE  dispensed_quantity5 int(11);
    DECLARE  appointment_date datetime;
    DECLARE  regimen_category varchar(255);
    DECLARE  location varchar(255);
    DECLARE  voided tinyint(1);
    DECLARE  void_reason varchar(255);
    DECLARE  date_voided date;
    DECLARE  voided_by int(11);
    DECLARE  encounter_datetime datetime;
    DECLARE  date_created datetime;
    DECLARE  creator varchar(255);
    DECLARE  visit_id INT(11);
    DECLARE  visit_date DATE;
    DECLARE  visit_patient_id INT(11);
    
    # Declare and initialise cursor for looping through the table
    DECLARE cur CURSOR FOR SELECT DISTINCT `bart1_intermediate_bare_bones`.`give_drugs_encounters`.id, `bart1_intermediate_bare_bones`.`give_drugs_encounters`.visit_encounter_id,            `bart1_intermediate_bare_bones`.`give_drugs_encounters`.old_enc_id,                   `bart1_intermediate_bare_bones`.`give_drugs_encounters`.patient_id,                  `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_drug_name1,             `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_dosage1,             `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_frequency1,          `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_drug_name2,             `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_dosage2,            `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_frequency2,          `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_drug_name3,            `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_dosage3,     `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_frequency3,         `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_drug_name4,             `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_dosage4,            `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_frequency4,              `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_drug_name5,            `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_dosage5, `bart1_intermediate_bare_bones`.`give_drugs_encounters`.pres_frequency5,                                                    `bart1_intermediate_bare_bones`.`give_drugs_encounters`.prescription_duration,                                                                     `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_drug_name1, `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_dosage1,    `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_quantity1, `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_drug_name2,  `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_dosage2,    `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_quantity2, `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_drug_name3,  `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_dosage3,    `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_quantity3, `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_drug_name4,  `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_dosage4,    `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_quantity4, `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_drug_name5,  `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_dosage5,    `bart1_intermediate_bare_bones`.`give_drugs_encounters`.dispensed_quantity5,  `bart1_intermediate_bare_bones`.`give_drugs_encounters`.appointment_date,  `bart1_intermediate_bare_bones`.`give_drugs_encounters`.regimen_category,          `bart1_intermediate_bare_bones`.`give_drugs_encounters`.location,                          `bart1_intermediate_bare_bones`.`give_drugs_encounters`.voided,                       `bart1_intermediate_bare_bones`.`give_drugs_encounters`.void_reason,                  `bart1_intermediate_bare_bones`.`give_drugs_encounters`.date_voided,                    `bart1_intermediate_bare_bones`.`give_drugs_encounters`.voided_by,  `bart1_intermediate_bare_bones`.`give_drugs_encounters`.encounter_datetime,                         `bart1_intermediate_bare_bones`.`give_drugs_encounters`.date_created,              `bart1_intermediate_bare_bones`.`give_drugs_encounters`.creator,   COALESCE(`bart1_intermediate_bare_bones`.`visit_encounters`.visit_date, `bart1_intermediate_bare_bones`.`give_drugs_encounters`.date_created) FROM 
`bart1_intermediate_bare_bones`.`give_drugs_encounters` 
        LEFT OUTER JOIN bart1_intermediate_bare_bones.visit_encounters ON 
        visit_encounter_id = bart1_intermediate_bare_bones.visit_encounters.id
       WHERE `bart1_intermediate_bare_bones`.`give_drugs_encounters`.`patient_id` = in_patient_id;

    # Declare loop position check
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    # Disable system checks and indexing to speed up processing
    # SET FOREIGN_KEY_CHECKS = 0;
    # SET UNIQUE_CHECKS = 0;
    # SET AUTOCOMMIT = 0;

    # Open cursor
    OPEN cur;
    
    # Declare loop for traversing through the records
    read_loop: LOOP
    
        # Get the fields into the variables declared earlier
        FETCH cur INTO  
            id,
            visit_encounter_id,
            old_enc_id,
            patient_id,
            pres_drug_name1,
            pres_dosage1,
            pres_frequency1,
            pres_drug_name2,
            pres_dosage2,
            pres_frequency2,
            pres_drug_name3,
            pres_dosage3,
            pres_frequency3,
            pres_drug_name4,
            pres_dosage4,
            pres_frequency4,
            pres_drug_name5,
            pres_dosage5,
            pres_frequency5,
            prescription_duration,
            dispensed_drug_name1,
            dispensed_dosage1,
            dispensed_quantity1,
            dispensed_drug_name2,
            dispensed_dosage2,
            dispensed_quantity2,
            dispensed_drug_name3,
            dispensed_dosage3,
            dispensed_quantity3,
            dispensed_drug_name4,
            dispensed_dosage4,
            dispensed_quantity4,
            dispensed_drug_name5,
            dispensed_dosage5,
            dispensed_quantity5,
            appointment_date,
            regimen_category,
            location,
            voided,
            void_reason,
            date_voided,
            voided_by,
            encounter_datetime,
            date_created,
            creator,
            visit_date; 

        # Check if we are done and exit loop if done
        IF done THEN
        
            LEAVE read_loop;
        
        END IF;
    
        # Not done, process the parameters

        # Map destination user to source user
        SET @creator = COALESCE((SELECT user_id FROM users WHERE username = creator), 1);

	      # Map destination user to source user
	      SET @provider = COALESCE((SELECT person_id FROM users WHERE user_id = @creator), 1);

        #get concepts_ids
        SET @pres_drug_name1_bart2_name = (SELECT bart2_two_name FROM drug_map
                                           WHERE bart_one_name = pres_drug_name1
                                           LIMIT 1);

        SET @pres_drug_name1_new_drug_id = (SELECT new_drug_id FROM drug_map
                                            WHERE bart2_two_name = @pres_drug_name1_bart2_name
                                            LIMIT 1);

        SET @pres_drug_name1_concept_id = (SELECT concept_id  FROM drug
                                           WHERE drug_id = @pres_drug_name1_new_drug_id
                                           LIMIT 1);

        SET @pres_drug_name2_bart2_name = (SELECT bart2_two_name FROM drug_map
                                           WHERE bart_one_name = pres_drug_name2
                                           LIMIT 1);

        SET @pres_drug_name2_new_drug_id = (SELECT new_drug_id FROM drug_map
                                            WHERE bart2_two_name = @pres_drug_name2_bart2_name
                                            LIMIT 1);

        SET @pres_drug_name2_concept_id = (SELECT concept_id  FROM drug
                                           WHERE drug_id = @pres_drug_name2_new_drug_id
                                           LIMIT 1);
                                           
        SET @pres_drug_name3_bart2_name = (SELECT bart2_two_name FROM drug_map
                                           WHERE bart_one_name = pres_drug_name3
                                           LIMIT 1);

        SET @pres_drug_name3_new_drug_id = (SELECT new_drug_id FROM drug_map
                                            WHERE bart2_two_name = @pres_drug_name3_bart2_name
                                            LIMIT 1);

        SET @pres_drug_name3_concept_id = (SELECT concept_id  FROM drug
                                           WHERE drug_id = @pres_drug_name3_new_drug_id
                                           LIMIT 1);
                                           
        SET @pres_drug_name4_bart2_name = (SELECT bart2_two_name FROM drug_map
                                           WHERE bart_one_name = pres_drug_name4 LIMIT 1);

        SET @pres_drug_name4_new_drug_id = (SELECT new_drug_id FROM drug_map
                                            WHERE bart2_two_name = @pres_drug_name4_bart2_name
                                            LIMIT 1);

        SET @pres_drug_name4_concept_id = (SELECT concept_id  FROM drug
                                           WHERE drug_id = @pres_drug_name4_new_drug_id
                                           LIMIT 1);

        SET @pres_drug_name5_bart2_name = (SELECT bart2_two_name FROM drug_map
                                           WHERE bart_one_name = pres_drug_name5
                                           LIMIT 1);

        SET @pres_drug_name5_new_drug_id = (SELECT new_drug_id FROM drug_map
                                            WHERE bart2_two_name = @pres_drug_name5_bart2_name
                                            LIMIT 1);

        SET @pres_drug_name5_concept_id = (SELECT concept_id  FROM drug
                                           WHERE drug_id = @pres_drug_name5_new_drug_id
                                           LIMIT 1);
                                           
        SET @cpt_started_concept_id = (SELECT concept_name.concept_id FROM concept_name
                            LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = "CPT started" AND voided = 0 AND retired = 0 LIMIT 1);

        SET @yes_concept_id = (SELECT concept_name.concept_id FROM concept_name
                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                            WHERE name = "Yes" AND voided = 0 AND retired = 0 LIMIT 1);
            
        # Get value_coded_name_id
        SET @yes_concept_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                            WHERE name = "Yes" AND voided = 0 AND retired = 0 LIMIT 1);

        SET @regimen_category_concept_id = (SELECT concept_name.concept_id FROM concept_name
                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                            WHERE name = "Regimen category" AND voided = 0 AND retired = 0 LIMIT 1);

        SET @what_type_of_antiretroviral_regime_concept_id = (SELECT concept_name.concept_id FROM concept_name
                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                            WHERE name = "What type of antiretroviral regimen" AND voided = 0 AND retired = 0 LIMIT 1);

        SET @amount_dispensed_concept_id = (SELECT concept_name.concept_id FROM concept_name
                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                            WHERE name = "Amount dispensed" AND voided = 0 AND retired = 0 LIMIT 1);
                                
        SET @arv_regimens_received_abstracted_construct_concept_id = (SELECT concept_name.concept_id FROM concept_name
                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                            WHERE name = "ARV regimens received abstracted construct" AND voided = 0
                            AND retired = 0 LIMIT 1);

       SET @arv_regimen_concept_id = ( SELECT concept_name.concept_id FROM concept_name
                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                            WHERE name = "Antiretroviral drugs" AND voided = 0 AND retired = 0 LIMIT 1);

       #get the bart2_drug_names from drug_map table
       SET @dispensed_drug_name1_bart2_name = (SELECT bart2_two_name FROM drug_map
                            WHERE bart_one_name = dispensed_drug_name1 LIMIT 1);

       SET @dispensed_drug_name1_concept_id = (SELECT new_drug_id  FROM drug_map
                            WHERE bart2_two_name = @dispensed_drug_name1_bart2_name LIMIT 1);

       SET @dispensed_drug_name1_new_concept_id = (SELECT concept_id  FROM drug
                            WHERE drug_id = @dispensed_drug_name1_concept_id LIMIT 1);

       SET @dispensed_drug_name2_bart2_name = (SELECT bart2_two_name FROM drug_map
                            WHERE bart_one_name = dispensed_drug_name2 LIMIT 1);

       SET @dispensed_drug_name2_concept_id = (SELECT new_drug_id  FROM drug_map
                            WHERE bart2_two_name = @dispensed_drug_name2_bart2_name LIMIT 1);

       SET @dispensed_drug_name2_new_concept_id = (SELECT concept_id  FROM drug
                            WHERE drug_id = @dispensed_drug_name2_concept_id LIMIT 1);

       SET @dispensed_drug_name3_bart2_name = (SELECT bart2_two_name FROM drug_map
                            WHERE bart_one_name = dispensed_drug_name3 LIMIT 1);

       SET @dispensed_drug_name3_concept_id = (SELECT new_drug_id  FROM drug_map
                            WHERE bart2_two_name = @dispensed_drug_name3_bart2_name LIMIT 1);

       SET @dispensed_drug_name3_new_concept_id = (SELECT concept_id  FROM drug
                            WHERE drug_id = @dispensed_drug_name3_concept_id LIMIT 1);
       
       SET @dispensed_drug_name4_bart2_name = (SELECT bart2_two_name FROM drug_map
                            WHERE bart_one_name = dispensed_drug_name4 LIMIT 1);

       SET @dispensed_drug_name4_concept_id = (SELECT new_drug_id  FROM drug_map
                            WHERE bart2_two_name = @dispensed_drug_name4_bart2_name LIMIT 1);

       SET @dispensed_drug_name4_new_concept_id = (SELECT concept_id  FROM drug
                            WHERE drug_id = @dispensed_drug_name4_concept_id LIMIT 1);

       SET @dispensed_drug_name5_bart2_name = (SELECT bart2_two_name FROM drug_map 
                            WHERE bart_one_name = dispensed_drug_name5 LIMIT 1);

       SET @dispensed_drug_name5_concept_id = (SELECT new_drug_id  FROM drug_map 
                            WHERE bart2_two_name = @dispensed_drug_name5_bart2_name LIMIT 1);

       SET @dispensed_drug_name5_new_concept_id = (SELECT concept_id  FROM drug
                            WHERE drug_id = @dispensed_drug_name5_concept_id LIMIT 1);
#-----------------------------------------------------------------------------------------------------------------------------------
      IF (pres_drug_name1 = 'Unknown ARV drug') THEN
        SET @pres_drug_name1 = NULL;
      ELSE
        SET @pres_drug_name1 = pres_drug_name1; 
      END IF;
      #Check if the field is not empty
      IF NOT ISNULL(@pres_drug_name1) THEN #-- AND (pres_drug_name1 != 'Unknown ARV drug') THEN #--1
        # Get id of encounter type
        SET @encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = "TREATMENT"  LIMIT 1);

        # Create encounter
        SET @encounter_uuid = (SELECT UUID());
          
        INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
        VALUES (old_enc_id, @encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @encounter_uuid)
        ON DUPLICATE KEY UPDATE encounter_id = old_enc_id, voided = 0;
         
        SET @encounter_id = (SELECT encounter_id FROM encounter WHERE uuid = @encounter_uuid);
        
        #check if it is cotrimozale
        IF (@pres_drug_name1_bart2_name = "Cotrimoxazole (480mg tablet)") THEN #--2
          SET @cpt_started_uuid = (SELECT UUID());

          INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, date_created, uuid)
          VALUES (patient_id, @cpt_started_concept_id, @encounter_id, encounter_datetime, @yes_concept_id, @yes_concept_name_id, @creator, date_created, @cpt_started_uuid);

          SET @pres_drug1_obs_id = (SELECT obs_id FROM obs WHERE uuid = @cpt_started_uuid);
        ELSE #--2

         # Create arv_regimen_type observation
         SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @pres_drug_name1_concept_id), 0);
         
         IF (@arv_drug_concept_id != 0) THEN
           SET @arv_regimen_type_uuid = (SELECT UUID());

           INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, creator, date_created, uuid)
           VALUES (patient_id, @what_type_of_antiretroviral_regime_concept_id, @encounter_id,  encounter_datetime, @pres_drug_name1_concept_id, @creator, date_created, @arv_regimen_type_uuid);
           
           SET @pres_drug1_obs_id = (SELECT obs_id FROM obs WHERE uuid = @arv_regimen_type_uuid);
         END IF;

        END IF;  #--2
        
        IF NOT ISNULL(prescription_duration) THEN #--4
          SET @auto_expire_date = NULL;
          SET @auto_expire_date = (SELECT 
                CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2)) 
                ELSE 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2)) 
                END AS prescription_duration_in_days);
        ELSE
          SET @auto_expire_date = NULL;
        END IF; #--11
                # create order
        SET @pres_drug_name1_uuid = (SELECT UUID());
        
        INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
        VALUES (1, @pres_drug_name1_concept_id, 1, @encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, @pres_drug_name1_uuid);
        
        SET @pres_drug1_order_id = (SELECT order_id FROM orders WHERE uuid = @pres_drug_name1_uuid);

        IF (pres_drug_name1 = dispensed_drug_name1) THEN #--5
          #create dispensed encounter without old_enc_id
          SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
          SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                            WHERE name = "DISPENSING" LIMIT 1);
          
          INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

          SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);

          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug1_order_id, @dispensed_drug_name1_concept_id, dispensed_dosage1, pres_dosage1, pres_frequency1, dispensed_quantity1);
          
          SET @amount_dispensed_drug_1 = (SELECT UUID());
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @dispensed_drug_name1_concept_id, dispensed_quantity1, @creator, date_created, @amount_dispensed_drug_1);

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name1_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);
          
          IF (@arv_drug_concept_id != 0) THEN  #--7
           #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
          END IF;

        ELSEIF (pres_drug_name1 = dispensed_drug_name2) THEN #--5
          #create dispensed encounter without old_enc_id
          SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
          SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                            WHERE name = "DISPENSING" LIMIT 1);
          
          INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
         
          SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);

          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug1_order_id, @dispensed_drug_name2_concept_id, dispensed_dosage2, dispensed_dosage2, pres_frequency1, dispensed_quantity2);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @dispensed_drug_name2_concept_id, dispensed_quantity2, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name2_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);
          
          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
         END IF;
        
        SET @dispensed_drug_name_2 = (SELECT "drug_2");
        
        ELSEIF (pres_drug_name1 = dispensed_drug_name3) THEN
          #create dispensed encounter without old_enc_id
          SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
          SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                            WHERE name = "DISPENSING" LIMIT 1);
          
          INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
         
          SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);

          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug1_order_id, @dispensed_drug_name3_concept_id, dispensed_dosage3, dispensed_dosage3, pres_frequency1, dispensed_quantity3);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @dispensed_drug_name3_concept_id, dispensed_quantity3, @creator, date_created, (SELECT UUID()));
          
          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name3_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7

            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));

          END IF;
         SET @dispensed_drug_name_3 = (SELECT dispensed_drug_name3);
        
       ELSEIF (pres_drug_name1 = dispensed_drug_name4) THEN #--5
          #create dispensed encounter without old_enc_id
          SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
          SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                            WHERE name = "DISPENSING" LIMIT 1);
          
          INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
         
          SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug1_order_id, @dispensed_drug_name4_concept_id, dispensed_dosage4, dispensed_dosage4, pres_frequency1, dispensed_quantity4);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @dispensed_drug_name4_concept_id, dispensed_quantity4, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name4_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
          END IF;    #--7         
          
          SET @dispensed_drug_name_4 = (SELECT dispensed_drug_name4);
        
        ELSEIF (pres_drug_name1 = dispensed_drug_name5) THEN
          #create dispensed encounter without old_enc_id
          SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
          SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                            WHERE name = "DISPENSING" LIMIT 1);
          
          INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
         
          SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose,  frequency, quantity)
          VALUES (@pres_drug1_order_id, @dispensed_drug_name5_concept_id, dispensed_dosage5, dispensed_dosage5, pres_frequency1, dispensed_quantity5);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @dispensed_drug_name5_concept_id, dispensed_quantity5, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name5_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug1_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
          END IF; #--7
          SET @dispensed_drug_name_5 = (SELECT dispensed_drug_name5);

        ELSE #--5        
          SET @prescription_without_dispensation = (SELECT pres_drug_name1);
     
          
          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency)
          VALUES (@pres_drug1_order_id, @pres_drug_name1_concept_id, pres_dosage1, pres_dosage1, pres_frequency1);
        END IF;    #--5  
      ELSE #--1
        #--implement dispensation without prescription
         IF NOT ISNULL(dispensed_drug_name1) THEN
           IF ( dispensed_drug_name1 = pres_drug_name5 ) THEN
              select dispensed_drug_name1, old_enc_id;
           ELSEIF ( dispensed_drug_name1 = pres_drug_name4 ) THEN
                select dispensed_name1, old_enc_id;
           ELSEIF ( dispensed_drug_name1 = pres_drug_name3 ) THEN
                  select dispensed_drug_name3, old_enc_id;
           ELSEIF ( dispensed_drug_name1 = pres_drug_name2 ) THEN
                  select dispensed_drug_name1, old_enc_id;
           ELSE
            #create dispensing encounter
            SET @dispensing_encounter_type_id = (SELECT encounter_type_id FROM encounter_type 
                                                 WHERE name = "DISPENSING"  LIMIT 1);

            # Create encounter
            SET @dispensing_encounter_without_pres_uuid = (SELECT UUID());
            
            SET @old_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM encounter
                                                         WHERE encounter_id = old_enc_id
                                                         AND encounter_type = 25),0);
            IF (@old_dispensing_encounter_id = 0) THEN
              INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
              VALUES (old_enc_id, @dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, @dispensing_encounter_without_pres_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

              SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());

            IF NOT ISNULL(prescription_duration) THEN #--11
              SET @auto_expire_date = NULL;
              SET @auto_expire_date = (SELECT
                  CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                     ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                   ELSE
                     ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                   END AS prescription_duration_in_days);
            ELSE
              SET @auto_expire_date = NULL;
            END IF; #--11
            # create order
            SET @dispensed_without_pres_order_uuid = (SELECT UUID());
            
            INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
            VALUES (1, @dispensed_drug_name1_new_concept_id, 1, old_enc_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, @dispensed_without_pres_order_uuid);

            SET @dispensed_without_pres_drug_order_id = (SELECT order_id FROM orders WHERE uuid = @dispensed_without_pres_order_uuid);

            SET @prescription_without_dispensation = (SELECT pres_drug_name1);

            #create drug_order without quantity
            INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
            VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name1_concept_id, dispensed_dosage1, pres_dosage1, pres_frequency1, dispensed_quantity1);

            #create amount dispensed obs
            INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
            VALUES (patient_id, @amount_dispensed_concept_id, old_enc_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name1_concept_id, dispensed_quantity1,@creator, date_created, (SELECT UUID()));

            SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name1_concept_id);

            SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

            IF (@arv_drug_concept_id != 0) THEN  #--7
              #create arv_regimen_received_abstracted_construct obs
              INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
              VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            END IF; #--7

            ELSE
              INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
              VALUES (@dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, @dispensing_encounter_without_pres_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

              SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());

            # create order
            SET @dispensed_without_pres_order_uuid1 = (SELECT UUID());

            IF NOT ISNULL(prescription_duration) THEN #--11
              SET @auto_expire_date = NULL;
              SET @auto_expire_date = (SELECT
                  CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                     ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                   ELSE
                     ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                   END AS prescription_duration_in_days);
            ELSE
              SET @auto_expire_date = NULL;
            END IF; #--11

            INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
            VALUES (1, @dispensed_drug_name1_new_concept_id, 1, @dispensing_without_pres_encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, @dispensed_without_pres_order_uuid1);

            SET @dispensed_without_pres_drug_order_id = (SELECT order_id FROM orders WHERE uuid = @dispensed_without_pres_order_uuid1);

            SET @prescription_without_dispensation = (SELECT pres_drug_name1);

            #create drug_order without quantity
            INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
            VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name1_concept_id, dispensed_dosage1, dispensed_dosage1, pres_frequency1, dispensed_quantity1);

            #create amount dispensed obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
            VALUES (patient_id, @amount_dispensed_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name1_concept_id, dispensed_quantity1,@creator, date_created, (SELECT UUID()));

            SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name1_concept_id);

            SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

            IF (@arv_drug_concept_id != 0) THEN  #--7
              #create arv_regimen_received_abstracted_construct obs
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
              VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));

            END IF; #--7
           END IF;
          END IF;
        END IF;
      END IF; #--1
   #--END IF;
#--------------------------------------------------------------------------------------------------------------------------------------------------
      IF (pres_drug_name2 = 'Unknown ARV drug') THEN
        SET @pres_drug_name2 = NULL;
      ELSE
        SET @pres_drug_name2 = pres_drug_name2; 
      END IF;

      #Check if the field is not empty
      IF NOT ISNULL(@pres_drug_name2) THEN #-- (pres_drug_name2 != 'Unknown ARV drug') THEN #--1
        SET @treatment_encounter_id = COALESCE((SELECT encounter_id FROM encounter WHERE encounter_id = old_enc_id),0);
        
        IF (@treatment_encounter_id = 0) THEN
          # Get id of encounter type
          SET @encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = "TREATMENT"  LIMIT 1);

          # Create encounter
          SET @encounter_uuid = (SELECT UUID());
            
          INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (old_enc_id, @encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @encounter_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id, voided = 0;
           
          SET @encounter_id = (SELECT encounter_id FROM encounter WHERE uuid = @encounter_uuid);
        ELSE
          SET @encounter_id = @treatment_encounter_id;
        END IF;

        #check if it is cotrimozale
        IF (@pres_drug_name2_bart2_name = "Cotrimoxazole (480mg tablet)") THEN #--2
          SET @cpt_started_uuid = (SELECT UUID());

          INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, date_created, uuid)
          VALUES (patient_id, @cpt_started_concept_id, @encounter_id, encounter_datetime, @yes_concept_id, @yes_concept_name_id, @creator, date_created, @cpt_started_uuid);

          SET @pres_drug2_obs_id = (SELECT obs_id FROM obs WHERE uuid = @cpt_started_uuid);
        ELSE #--2

         # Create arv_regimen_type observation
         SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @pres_drug_name2_concept_id), 0);
         
         IF (@arv_drug_concept_id != 0) THEN
           # Create observation
           SET @arv_regimen_type_uuid = (SELECT UUID());

           INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, creator, date_created, uuid)
           VALUES (patient_id, @what_type_of_antiretroviral_regime_concept_id, @encounter_id,  encounter_datetime, @pres_drug_name2_concept_id, @creator, date_created, @arv_regimen_type_uuid);
           
           SET @pres_drug2_obs_id = (SELECT obs_id FROM obs WHERE uuid = @arv_regimen_type_uuid);
         END IF;
        END IF;  #--2
        
        # create order
        SET @pres_drug_name2_uuid = (SELECT UUID());
               
        IF NOT ISNULL(prescription_duration) THEN #--4
          SET @auto_expire_date = NULL;
          SET @auto_expire_date = (SELECT 
                CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2)) 
                ELSE 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2)) 
                END AS prescription_duration_in_days);
        ELSE
          SET @auto_expire_date = NULL;
        END IF; #--11
              
        INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
        VALUES (1, @pres_drug_name2_concept_id, 1, @encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, @pres_drug_name2_uuid);
        SET @pres_drug2_order_id = (SELECT order_id FROM orders WHERE uuid = @pres_drug_name2_uuid);

        IF (pres_drug_name2 = dispensed_drug_name1) THEN #--5
          #create dispensed encounter without old_enc_id
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter tenc WHERE tenc.encounter_datetime = encounter_datetime AND patient_id = tenc.patient_id AND tenc.encounter_type = 54), 0);
          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
            SET @new_dispensed_encounter_id = (SELECT LAST_INSERT_ID());
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;

          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug2_order_id, @dispensed_drug_name1_concept_id, dispensed_dosage1, dispensed_dosage1, pres_frequency2, dispensed_quantity1);
          
          SET @amount_dispensed_drug_2 = (SELECT UUID());
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @dispensed_drug_name1_concept_id, dispensed_quantity1, @creator, date_created, @amount_dispensed_drug_2);

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name1_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs

            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID())); 
          END IF;
          
          SET @dispensed_drug_name_2 = (SELECT encounter_id FROM obs WHERE uuid = @amount_dispensed_drug_2);

        ELSEIF (pres_drug_name2 = dispensed_drug_name2) THEN #--5
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);
          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity

          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug2_order_id, @dispensed_drug_name2_concept_id, dispensed_dosage2, dispensed_dosage2, pres_frequency2, dispensed_quantity2);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @dispensed_drug_name2_concept_id, dispensed_quantity2, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name2_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
         END IF;

         SET @dispensed_drug_name_2 = (SELECT "drug_2");
        
        ELSEIF (pres_drug_name2 = dispensed_drug_name3) THEN
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug2_order_id, @dispensed_drug_name3_concept_id, dispensed_dosage3, dispensed_dosage3, pres_frequency2, dispensed_quantity3);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @dispensed_drug_name3_concept_id, dispensed_quantity3, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name3_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs

            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));            
          END IF;
          
         SET @dispensed_drug_name_3 = (SELECT dispensed_drug_name3);
        
       ELSEIF (pres_drug_name2 = dispensed_drug_name4) THEN #--5
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug2_order_id, @dispensed_drug_name4_concept_id, dispensed_dosage4, dispensed_dosage4, pres_frequency2, dispensed_quantity4);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @dispensed_drug_name4_concept_id, dispensed_quantity4, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name4_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
          END IF;    #--7         
          SET @dispensed_drug_name_4 = (SELECT dispensed_drug_name4);
        
        ELSEIF (pres_drug_name2 = dispensed_drug_name5) THEN
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug2_order_id, @dispensed_drug_name5_concept_id, dispensed_dosage5, dispensed_dosage5, pres_frequency2, dispensed_quantity5);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @dispensed_drug_name5_concept_id, dispensed_quantity5, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name5_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug2_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));

          END IF; #--7
          SET @dispensed_drug_name_5 = (SELECT dispensed_drug_name5);

        ELSE #--5        
          SET @prescription_without_dispensation = (SELECT pres_drug_name2);
          #create drug_order without quantity
        
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency)
          VALUES (@pres_drug2_order_id, @pres_drug_name2_concept_id, pres_dosage2, pres_dosage2, pres_frequency2);
        END IF;    #--5  
      ELSE #--1
      #--implement dispensation without prescription
      IF NOT ISNULL(dispensed_drug_name2) THEN #--if dispensed2 is not null
        IF ( dispensed_drug_name2 = pres_drug_name5 ) THEN
          select pres_drug_name5, old_enc_id;
        ELSEIF ( dispensed_drug_name2 = pres_drug_name4 ) THEN
          select pres_drug_name4, old_enc_id;
        ELSEIF ( dispensed_drug_name2 = pres_drug_name3 ) THEN
          select pres_drug_name3, old_enc_id;
        ELSEIF ( dispensed_drug_name2 =  pres_drug_name2) THEN
          select  pres_drug_name2, old_enc_id;
        ELSEIF ( dispensed_drug_name2 =  pres_drug_name1) THEN
          select pres_drug_name1, old_enc_id;
        ELSE
        
        #create dispensing encounter
        SET @dispensing_encounter_type_id = (SELECT encounter_type_id FROM encounter_type 
                                             WHERE name = "DISPENSING"  LIMIT 1);
                                             
        SET @old_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM encounter
                                                     WHERE encounter_id = old_enc_id
                                                     AND encounter_type = 25),0);
       
        IF (@old_dispensing_encounter_id = 0) THEN #--onee
          INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (old_enc_id, @dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, (SELECT UUID())) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

          SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());

          IF NOT ISNULL(prescription_duration) THEN #--11
            SET @auto_expire_date = NULL;
            SET @auto_expire_date = (SELECT
                  CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                    ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                  ELSE
                    ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                  END AS prescription_duration_in_days);
          ELSE
            SET @auto_expire_date = NULL;
          END IF; #--11
          
          INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
          VALUES (1, @dispensed_drug_name2_new_concept_id, 1, @dispensing_without_pres_encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, (SELECT UUID()));

          SET @dispensed_without_pres_drug_order_id = (SELECT LAST_INSERT_ID());

          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name2_concept_id, dispensed_dosage2, pres_dosage2, pres_frequency2, dispensed_quantity2);

          #create amount dispensed obs
          INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name2_concept_id, dispensed_quantity2,@creator, date_created, (SELECT UUID()));
        
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                               WHERE concept_set = @arv_regimen_concept_id
                                               AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
         END IF; #--7
        
        ELSE #--onee
          SET @old_temp_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter tnc
                                                 WHERE tnc.patient_id = patient_id
                                                 AND tnc.encounter_type = 54
                                                 AND tnc.encounter_datetime = encounter_datetime
                                                 LIMIT 1), 0 );
          
          IF (@old_temp_encounter_id = 0) THEN
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, (SELECT UUID()));
            SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());
          ELSE
            SET @dispensing_without_pres_encounter_id = (@old_temp_encounter_id);
          END IF;

          IF NOT ISNULL(prescription_duration) THEN #--11
            SET @auto_expire_date = NULL;
            SET @auto_expire_date = (SELECT
                    CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                      ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                    ELSE
                      ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                    END AS prescription_duration_in_days);
          ELSE
            SET @auto_expire_date = NULL;
          END IF; #--11
          
          INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
          VALUES (1, @dispensed_drug_name2_new_concept_id, 1, @dispensing_without_pres_encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, (SELECT UUID()));
          
          SET @dispensed_without_pres_drug_order_id = (SELECT LAST_INSERT_ID());
          
          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name2_concept_id, dispensed_dosage2, dispensed_dosage2, pres_frequency2, dispensed_quantity2);

          #create amount dispensed obs
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name2_concept_id, dispensed_quantity2,@creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name2_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                               WHERE concept_set = @arv_regimen_concept_id
                                               AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));

         END IF; #--7 
        END IF; #--onee
       END IF;
      END IF;
      END IF;
        #--END IF; #---------------------------------------------------------------------------------------------------------------------------------------------------
      IF (pres_drug_name3 = 'Unknown ARV drug') THEN
        SET @pres_drug_name3 = NULL;
      ELSE
        SET @pres_drug_name3 = pres_drug_name3; 
      END IF;

      #Check if the field is not empty
      IF NOT ISNULL(@pres_drug_name3) THEN #--(pres_drug_name3 != 'Unknown ARV drug') THEN #--1
        SET @treatment_encounter_id = COALESCE((SELECT encounter_id FROM encounter WHERE encounter_id = old_enc_id),0);
        
        IF (@treatment_encounter_id = 0) THEN
          # Get id of encounter type
          SET @encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = "TREATMENT"  LIMIT 1);

          # Create encounter
          SET @encounter_uuid = (SELECT UUID());
            
          INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (old_enc_id, @encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @encounter_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id, voided = 0;
           
          SET @encounter_id = (SELECT encounter_id FROM encounter WHERE uuid = @encounter_uuid);
        ELSE
          SET @encounter_id = @treatment_encounter_id;
        END IF;

        #check if it is cotrimozale
        IF (@pres_drug_name3_bart2_name = "Cotrimoxazole (480mg tablet)") THEN #--2
          SET @cpt_started_uuid = (SELECT UUID());

          INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, date_created, uuid)
          VALUES (patient_id, @cpt_started_concept_id, @encounter_id, encounter_datetime, @yes_concept_id, @yes_concept_name_id, @creator, date_created, @cpt_started_uuid);

          SET @pres_drug3_obs_id = (SELECT obs_id FROM obs WHERE uuid = @cpt_started_uuid);
        ELSE #--2
         # Create arv_regimen_type observation
         SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @pres_drug_name3_concept_id), 0);
         
         IF (@arv_drug_concept_id != 0) THEN
          # Create observation
          SET @arv_regimen_type_uuid = (SELECT UUID());

          INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, creator, date_created, uuid)
          VALUES (patient_id, @what_type_of_antiretroviral_regime_concept_id, @encounter_id,  encounter_datetime, @pres_drug_name3_concept_id, @creator, date_created, @arv_regimen_type_uuid);
         
          SET @pres_drug3_obs_id = (SELECT obs_id FROM obs WHERE uuid = @arv_regimen_type_uuid);
         END IF;
        END IF;  #--2

        # create order
        SET @pres_drug_name3_uuid = (SELECT UUID());
               
        IF NOT ISNULL(prescription_duration) THEN #--4
          SET @auto_expire_date = NULL;
          SET @auto_expire_date = (SELECT 
                CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2)) 
                ELSE 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2)) 
                END AS prescription_duration_in_days);
        ELSE
          SET @auto_expire_date = NULL;
        END IF; #--11

        INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
        VALUES (1, @pres_drug_name3_concept_id, 1, @encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, @pres_drug_name3_uuid);
        SET @pres_drug3_order_id = (SELECT order_id FROM orders WHERE uuid = @pres_drug_name3_uuid);

        IF (pres_drug_name3 = dispensed_drug_name1) THEN #--5
          #create dispensed encounter without old_enc_id
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;

          #create drug_order with quantity
        
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug3_order_id, @dispensed_drug_name1_concept_id, dispensed_dosage1, dispensed_dosage1, pres_frequency3, dispensed_quantity1);
          
          SET @amount_dispensed_drug_3 = (SELECT UUID());
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @dispensed_drug_name1_concept_id, dispensed_quantity1, @creator, date_created, @amount_dispensed_drug_3);
           
          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name1_concept_id);           
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
          END IF;
          
          SET @dispensed_drug_name_3 = (SELECT encounter_id FROM obs WHERE uuid = @amount_dispensed_drug_3);

        ELSEIF (pres_drug_name3 = dispensed_drug_name2) THEN #--5
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;

          #create drug_order with quantity
          
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose,  frequency, quantity)
          VALUES (@pres_drug3_order_id, @dispensed_drug_name2_concept_id, dispensed_dosage2, dispensed_dosage2, pres_frequency3, dispensed_quantity2);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @dispensed_drug_name2_concept_id, dispensed_quantity2, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name2_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
         END IF;
        SET @dispensed_drug_name_3 = (SELECT "drug_2");
        
        ELSEIF (pres_drug_name3 = dispensed_drug_name3) THEN
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;

          #create drug_order with quantity

          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose,  dose, frequency, quantity)
          VALUES (@pres_drug3_order_id, @dispensed_drug_name3_concept_id, dispensed_dosage3, pres_dosage3, pres_frequency3, dispensed_quantity3);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @dispensed_drug_name3_concept_id, dispensed_quantity3, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name3_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
          END IF;
         SET @dispensed_drug_name_3 = (SELECT dispensed_drug_name3);
        
       ELSEIF (pres_drug_name3 = dispensed_drug_name4) THEN #--5
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;

          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug3_order_id, @dispensed_drug_name4_concept_id, dispensed_dosage4, dispensed_dosage4, pres_frequency3, dispensed_quantity4);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @dispensed_drug_name4_concept_id, dispensed_quantity4, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name4_concept_id);          
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
          END IF;    #--7         
          SET @dispensed_drug_name_4 = (SELECT dispensed_drug_name4);
        
        ELSEIF (pres_drug_name3 = dispensed_drug_name5) THEN
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;

          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug3_order_id, @dispensed_drug_name5_concept_id, dispensed_dosage5, dispensed_dosage5, pres_frequency3, dispensed_quantity5);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @dispensed_drug_name5_concept_id, dispensed_quantity5, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name5_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug3_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            
          END IF; #--7
          SET @dispensed_drug_name_5 = (SELECT dispensed_drug_name5);

        ELSE #--5        
          SET @prescription_without_dispensation = (SELECT pres_drug_name3);
          
          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency)
          VALUES (@pres_drug3_order_id, @pres_drug_name3_concept_id, pres_dosage3, pres_dosage3, pres_frequency3);
        END IF;    #--5  
      ELSE #--1
        #--implement dispensation without prescription
        IF NOT ISNULL(dispensed_drug_name3) THEN
           IF ( dispensed_drug_name3 = pres_drug_name5 ) THEN
              select dispensed_drug_name3, old_enc_id;
           ELSEIF ( dispensed_drug_name3 = pres_drug_name4 ) THEN
                select dispensed_name3, old_enc_id;
           ELSEIF ( dispensed_drug_name3 = pres_drug_name3 ) THEN
                  select dispensed_drug_name3, old_enc_id;
           ELSEIF ( dispensed_drug_name3 =  pres_drug_name3) THEN
                  select dispensed_drug_name3, old_enc_id;
           ELSEIF ( dispensed_drug_name3 =  pres_drug_name1) THEN
           select dispensed_drug_name3, old_enc_id;
           ELSE
        #create dispensing encounter
        SET @dispensing_encounter_type_id = (SELECT encounter_type_id FROM encounter_type 
                                             WHERE name = "DISPENSING"  LIMIT 1);
                                             
        SET @old_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM encounter
                                                     WHERE encounter_id = old_enc_id
                                                     AND encounter_type = 25),0);
       
        IF (@old_dispensing_encounter_id = 0) THEN #--onee
          INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (old_enc_id, @dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, (SELECT UUID())) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

          SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());

          IF NOT ISNULL(prescription_duration) THEN #--11
            SET @auto_expire_date = NULL;
            SET @auto_expire_date = (SELECT
                  CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                    ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                  ELSE
                    ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                  END AS prescription_duration_in_days);
          ELSE
            SET @auto_expire_date = NULL;
          END IF; #--11
          
          INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
          VALUES (1, @dispensed_drug_name3_new_concept_id, 1, @dispensing_without_pres_encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, (SELECT UUID()));

          SET @dispensed_without_pres_drug_order_id = (SELECT LAST_INSERT_ID());

          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name3_concept_id, dispensed_dosage3, pres_dosage3, pres_frequency3, dispensed_quantity3);

          #create amount dispensed obs
          INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name3_concept_id, dispensed_quantity3,@creator, date_created, (SELECT UUID()));
        
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                               WHERE concept_set = @arv_regimen_concept_id
                                               AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
         END IF; #--7
        
        ELSE #--onee
          SET @old_temp_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter tnc
                                                 WHERE tnc.patient_id = patient_id
                                                 AND tnc.encounter_type = 54
                                                 AND tnc.encounter_datetime = encounter_datetime
                                                 LIMIT 1), 0 );
          
          IF (@old_temp_encounter_id = 0) THEN
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, (SELECT UUID()));
            SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());
          ELSE
            SET @dispensing_without_pres_encounter_id = (@old_temp_encounter_id);
          END IF;

          IF NOT ISNULL(prescription_duration) THEN #--11
            SET @auto_expire_date = NULL;
            SET @auto_expire_date = (SELECT
                    CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                      ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                    ELSE
                      ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                    END AS prescription_duration_in_days);
          ELSE
            SET @auto_expire_date = NULL;
          END IF; #--11
          
          INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
          VALUES (1, @dispensed_drug_name3_new_concept_id, 1, @dispensing_without_pres_encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, (SELECT UUID()));
          
          SET @dispensed_without_pres_drug_order_id = (SELECT LAST_INSERT_ID());
          
          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name3_concept_id, dispensed_dosage3, dispensed_dosage3, pres_frequency3, dispensed_quantity3);

          #create amount dispensed obs
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name3_concept_id, dispensed_quantity3,@creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name3_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                               WHERE concept_set = @arv_regimen_concept_id
                                               AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));

         END IF; #--7 
        END IF; #--onee
       END IF;
      END IF;
      END IF;
      #--    END IF;
#--------------------------------------------------------------------------------------------------------------------------------------------------
      IF (pres_drug_name4 = 'Unknown ARV drug') THEN
        SET @pres_drug_name4 = NULL;
      ELSE
        SET @pres_drug_name4 = pres_drug_name4; 
      END IF;
      #Check if the field is not empty

      IF NOT ISNULL(@pres_drug_name4) THEN #-- AND (pres_drug_name4 != 'Unknown ARV drug') THEN #--1
        SET @treatment_encounter_id = COALESCE((SELECT encounter_id FROM encounter WHERE encounter_id = old_enc_id),0);
        
        IF (@treatment_encounter_id = 0) THEN
          # Get id of encounter type
          SET @encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = "TREATMENT"  LIMIT 1);

          # Create encounter
          SET @encounter_uuid = (SELECT UUID());
            
          INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (old_enc_id, @encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @encounter_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id, voided = 0;
           
          SET @encounter_id = (SELECT encounter_id FROM encounter WHERE uuid = @encounter_uuid);
        ELSE
          SET @encounter_id = @treatment_encounter_id;
        END IF;

        #check if it is cotrimozale
        IF (@pres_drug_name4_bart2_name = "Cotrimoxazole (480mg tablet)") THEN #--2
          SET @cpt_started_uuid = (SELECT UUID());

          INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, date_created, uuid)
          VALUES (patient_id, @cpt_started_concept_id, @encounter_id, encounter_datetime, @yes_concept_id, @yes_concept_name_id, @creator, date_created, @cpt_started_uuid);

          SET @pres_drug4_obs_id = (SELECT obs_id FROM obs WHERE uuid = @cpt_started_uuid);
        ELSE #--2

         # Create arv_regimen_type observation
         SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @pres_drug_name4_concept_id), 0);
         
         IF (@arv_drug_concept_id != 0) THEN
            # Create observation
           SET @arv_regimen_type_uuid = (SELECT UUID());

           INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, creator, date_created, uuid)
           VALUES (patient_id, @what_type_of_antiretroviral_regime_concept_id, @encounter_id,  encounter_datetime, @pres_drug_name4_concept_id, @creator, date_created, @arv_regimen_type_uuid);
           
           SET @pres_drug4_obs_id = (SELECT obs_id FROM obs WHERE uuid = @arv_regimen_type_uuid);
         END IF;
        END IF;  #--2
        
        # create order
        SET @pres_drug_name4_uuid = (SELECT UUID());
               
        IF NOT ISNULL(prescription_duration) THEN #--4
          SET @auto_expire_date = NULL;          
          SET @auto_expire_date = (SELECT 
                CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2)) 
                ELSE 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2)) 
                END AS prescription_duration_in_days);
        ELSE
          SET @auto_expire_date = NULL;
        END IF; #--11
              
        INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
        VALUES (1, @pres_drug_name4_concept_id, 1, @encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, @pres_drug_name4_uuid);
        SET @pres_drug4_order_id = (SELECT order_id FROM orders WHERE uuid = @pres_drug_name4_uuid);

        IF (pres_drug_name4 = dispensed_drug_name1) THEN #--5
          #create dispensed encounter without old_enc_id
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;

          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose,  frequency, quantity)
          VALUES (@pres_drug4_order_id, @dispensed_drug_name1_concept_id, dispensed_dosage1, dispensed_dosage1, pres_frequency4, dispensed_quantity1);
          
          SET @amount_dispensed_drug_4 = (SELECT UUID());
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @dispensed_drug_name1_concept_id, dispensed_quantity1, @creator, date_created, @amount_dispensed_drug_4);
           
          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name1_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            
          END IF;
          
          SET @dispensed_drug_name_4 = (SELECT encounter_id FROM obs WHERE uuid = @amount_dispensed_drug_4);

        ELSEIF (pres_drug_name4 = dispensed_drug_name2) THEN #--5
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose,  frequency, quantity)
          VALUES (@pres_drug4_order_id, @dispensed_drug_name2_concept_id, dispensed_dosage2, dispensed_dosage2, pres_frequency4, dispensed_quantity2);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @dispensed_drug_name2_concept_id, dispensed_quantity2, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name2_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
         END IF;
         
        SET @dispensed_drug_name_4 = (SELECT "drug_2");
        
        ELSEIF (pres_drug_name4 = dispensed_drug_name3) THEN
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
         
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose,  frequency, quantity)
          VALUES (@pres_drug4_order_id, @dispensed_drug_name3_concept_id, dispensed_dosage3, dispensed_dosage3, pres_frequency4, dispensed_quantity3);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @dispensed_drug_name3_concept_id, dispensed_quantity3, @creator, date_created, (SELECT UUID()));

         SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name3_concept_id);
         SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            
          END IF;
         SET @dispensed_drug_name_4 = (SELECT dispensed_drug_name3);
        
       ELSEIF (pres_drug_name4 = dispensed_drug_name4) THEN #--5
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug4_order_id, @dispensed_drug_name4_concept_id, dispensed_dosage4, pres_dosage4, pres_frequency4, dispensed_quantity4);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @dispensed_drug_name4_concept_id, dispensed_quantity4, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name4_concept_id);          
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            
          END IF;    #--7         
          SET @dispensed_drug_name_4 = (SELECT dispensed_drug_name4);
        
        ELSEIF (pres_drug_name4 = dispensed_drug_name5) THEN
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug4_order_id, @dispensed_drug_name5_concept_id, dispensed_dosage5, dispensed_dosage5, pres_frequency4, dispensed_quantity5);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @dispensed_drug_name5_concept_id, dispensed_quantity5, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name5_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug4_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            
          END IF; #--7
          SET @dispensed_drug_name_5 = (SELECT dispensed_drug_name5);

        ELSE #--5        
          SET @prescription_without_dispensation = (SELECT pres_drug_name4);
          #create drug_order without quantity
        
         INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose,  frequency)
          VALUES (@pres_drug4_order_id, @dispensed_drug_name4_concept_id, dispensed_dosage4, pres_dosage4, pres_frequency4);
        END IF;    #--5  
      ELSE #--1
        #--implement dispensation without prescription
        IF NOT ISNULL(dispensed_drug_name4) THEN
           IF ( dispensed_drug_name4 = pres_drug_name5 ) THEN
              select dispensed_drug_name4, old_enc_id;
           ELSEIF ( dispensed_drug_name4 = pres_drug_name4 ) THEN
                select dispensed_name4, old_enc_id;
           ELSEIF ( dispensed_drug_name4 = pres_drug_name4 ) THEN
                  select dispensed_drug_name4, old_enc_id;
           ELSEIF ( dispensed_drug_name4 =  pres_drug_name4) THEN
                  select dispensed_drug_name3, old_enc_id;
           ELSEIF ( dispensed_drug_name4 =  pres_drug_name1) THEN
                select dispensed_drug_name3, old_enc_id;
           ELSE
        #create dispensing encounter
        SET @dispensing_encounter_type_id = (SELECT encounter_type_id FROM encounter_type 
                                             WHERE name = "DISPENSING"  LIMIT 1);
                                             
        SET @old_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM encounter
                                                     WHERE encounter_id = old_enc_id
                                                     AND encounter_type = 25),0);
       
        IF (@old_dispensing_encounter_id = 0) THEN #--onee
          INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (old_enc_id, @dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, (SELECT UUID())) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

          SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());

          IF NOT ISNULL(prescription_duration) THEN #--11
            SET @auto_expire_date = NULL;
            SET @auto_expire_date = (SELECT
                  CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                    ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                  ELSE
                    ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                  END AS prescription_duration_in_days);
          ELSE
            SET @auto_expire_date = NULL;
          END IF; #--11
          
          INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
          VALUES (1, @dispensed_drug_name4_new_concept_id, 1, @dispensing_without_pres_encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, (SELECT UUID()));

          SET @dispensed_without_pres_drug_order_id = (SELECT LAST_INSERT_ID());

          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name4_concept_id, dispensed_dosage4, pres_dosage4, pres_frequency4, dispensed_quantity4);

          #create amount dispensed obs
          INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name4_concept_id, dispensed_quantity4,@creator, date_created, (SELECT UUID()));
        
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                               WHERE concept_set = @arv_regimen_concept_id
                                               AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
         END IF; #--7
        
        ELSE #--onee
          SET @old_temp_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter tnc
                                                 WHERE tnc.patient_id = patient_id
                                                 AND tnc.encounter_type = 54
                                                 AND tnc.encounter_datetime = encounter_datetime
                                                 LIMIT 1), 0 );
          
          IF (@old_temp_encounter_id = 0) THEN
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, (SELECT UUID()));
            SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());
          ELSE
            SET @dispensing_without_pres_encounter_id = (@old_temp_encounter_id);
          END IF;

          IF NOT ISNULL(prescription_duration) THEN #--11
            SET @auto_expire_date = NULL;
            SET @auto_expire_date = (SELECT
                    CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                      ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                    ELSE
                      ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                    END AS prescription_duration_in_days);
          ELSE
            SET @auto_expire_date = NULL;
          END IF; #--11
          
          INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
          VALUES (1, @dispensed_drug_name4_new_concept_id, 1, @dispensing_without_pres_encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, (SELECT UUID()));
          
          SET @dispensed_without_pres_drug_order_id = (SELECT LAST_INSERT_ID());
          
          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name4_concept_id, dispensed_dosage4, dispensed_dosage4, pres_frequency4, dispensed_quantity4);

          #create amount dispensed obs
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name4_concept_id, dispensed_quantity4,@creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name4_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                               WHERE concept_set = @arv_regimen_concept_id
                                               AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));

         END IF; #--7 
        END IF; #--onee
       END IF;
      END IF;
      END IF;
   #--END IF;
#--------------------------------------------------------------------------------------------------------------------------------------------------
      IF (pres_drug_name5 = 'Unknown ARV drug') THEN
        SET @pres_drug_name5 = NULL;
      ELSE
        SET @pres_drug_name5 = pres_drug_name5; 
      END IF;

      #Check if the field is not empty

      IF NOT ISNULL(@pres_drug_name5) THEN #-- AND (pres_drug_name5 != 'Unknown ARV drug') THEN #--1
        SET @treatment_encounter_id = COALESCE((SELECT encounter_id FROM encounter WHERE encounter_id = old_enc_id),0);
        
        IF (@treatment_encounter_id = 0) THEN
          # Get id of encounter type
          SET @encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = "TREATMENT"  LIMIT 1);

          # Create encounter
          SET @encounter_uuid = (SELECT UUID());
            
          INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (old_enc_id, @encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @encounter_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id, voided = 0;
           
          SET @encounter_id = (SELECT encounter_id FROM encounter WHERE uuid = @encounter_uuid);
        ELSE
          SET @encounter_id = @treatment_encounter_id;
        END IF;

        #check if it is cotrimozale
        IF (@pres_drug_name5_bart2_name = "Cotrimoxazole (480mg tablet)") THEN #--2
          SET @cpt_started_uuid = (SELECT UUID());

          INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, date_created, uuid)
          VALUES (patient_id, @cpt_started_concept_id, @encounter_id, encounter_datetime, @yes_concept_id, @yes_concept_name_id, @creator, date_created, @cpt_started_uuid);

          SET @pres_drug5_obs_id = (SELECT obs_id FROM obs WHERE uuid = @cpt_started_uuid);
        ELSE #--2
         # Create arv_regimen_type observation
         SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @pres_drug_name5_concept_id), 0);
         
         IF (@arv_drug_concept_id != 0) THEN
           # Create observation
           SET @arv_regimen_type_uuid = (SELECT UUID());

           INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, creator, date_created, uuid)
           VALUES (patient_id, @what_type_of_antiretroviral_regime_concept_id, @encounter_id,  encounter_datetime, @pres_drug_name5_concept_id, @creator, date_created, @arv_regimen_type_uuid);
           
           SET @pres_drug5_obs_id = (SELECT obs_id FROM obs WHERE uuid = @arv_regimen_type_uuid);
         END IF;
        END IF;  #--2
        
        # create order
        SET @pres_drug_name5_uuid = (SELECT UUID());
               
        IF NOT ISNULL(prescription_duration) THEN #--4
          SET @auto_expire_date = NULL;
          SET @auto_expire_date = (SELECT 
                CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2)) 
                ELSE 
                  ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2)) 
                END AS prescription_duration_in_days);
        ELSE
          SET @auto_expire_date = NULL;
        END IF; #--11
              
        INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
        VALUES (1, @pres_drug_name5_concept_id, 1, @encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, @pres_drug_name5_uuid);
        SET @pres_drug5_order_id = (SELECT order_id FROM orders WHERE uuid = @pres_drug_name5_uuid);

        IF (pres_drug_name5 = dispensed_drug_name1) THEN #--5
          #create dispensed encounter without old_enc_id
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;

          #create drug_order with quantity
         
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug5_order_id, @dispensed_drug_name1_concept_id, dispensed_dosage1, dispensed_dosage1, pres_frequency5, dispensed_quantity1);
          
          SET @amount_dispensed_drug_5 = (SELECT UUID());
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @dispensed_drug_name1_concept_id, dispensed_quantity1, @creator, date_created, @amount_dispensed_drug_5);

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name1_concept_id);
          SET @arv_drug_concept_id = COALESCE(( SELECT concept_id FROM concept_set
                                                WHERE concept_set = @arv_regimen_concept_id
                                                AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7          
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
          END IF;
          
          SET @dispensed_drug_name_5 = (SELECT encounter_id FROM obs WHERE uuid = @amount_dispensed_drug_5);

        ELSEIF (pres_drug_name5 = dispensed_drug_name2) THEN #--5
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose,  dose, frequency, quantity)
          VALUES (@pres_drug5_order_id, @dispensed_drug_name2_concept_id, dispensed_dosage2, dispensed_dosage2, pres_frequency5, dispensed_quantity2);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @dispensed_drug_name2_concept_id, dispensed_quantity2, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name2_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7  
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            
         END IF;
        SET @dispensed_drug_name_5 = (SELECT "drug_2");
        
        ELSEIF (pres_drug_name5 = dispensed_drug_name3) THEN
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug5_order_id, @dispensed_drug_name3_concept_id, dispensed_dosage3, dispensed_dosage3, pres_frequency5, dispensed_quantity3);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @dispensed_drug_name3_concept_id, dispensed_quantity3, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name3_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7  
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            
          END IF;
         SET @dispensed_drug_name_5 = (SELECT dispensed_drug_name3);
        
       ELSEIF (pres_drug_name5 = dispensed_drug_name4) THEN #--5
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose,  frequency, quantity)
          VALUES (@pres_drug5_order_id, @dispensed_drug_name4_concept_id, dispensed_dosage4, dispensed_dosage4, pres_frequency5, dispensed_quantity4);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @dispensed_drug_name4_concept_id, dispensed_quantity4, @creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name4_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            
          END IF;    #--7         
          SET @dispensed_drug_name_4 = (SELECT dispensed_drug_name4);
        
        ELSEIF (pres_drug_name5 = dispensed_drug_name5) THEN
          SET @new_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter WHERE encounter_id = @new_dispensed_encounter_id), 0);

          IF (@new_dispensing_encounter_id = 0) THEN
            SET @new_dispensed_encounter_id_uuid = (SELECT UUID());
            SET @dispensing_encounter_type = (SELECT encounter_type_id FROM encounter_type
                                              WHERE name = "DISPENSING" LIMIT 1);
            
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type, patient_id, @provider, encounter_datetime, @creator, date_created, @new_dispensed_encounter_id_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
           
            SET @new_dispensed_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @new_dispensed_encounter_id_uuid);
          ELSE
            SET @new_dispensed_encounter_id = @new_dispensing_encounter_id;
          END IF;
          
          #create drug_order with quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@pres_drug5_order_id, @dispensed_drug_name5_concept_id, dispensed_dosage5, pres_dosage5, pres_frequency5, dispensed_quantity5);
          
          #create amount dispensed observation
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @dispensed_drug_name5_concept_id, dispensed_quantity5, @creator, date_created, (SELECT UUID()));
          
          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name5_concept_id);
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                              WHERE concept_set = @arv_regimen_concept_id
                                              AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @new_dispensed_encounter_id, @pres_drug5_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
            
          END IF; #--7
          SET @dispensed_drug_name_5 = (SELECT dispensed_drug_name5);

        ELSE #--5        
          SET @prescription_without_dispensation = (SELECT pres_drug_name5);
          #create drug_order without quantity
          
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose,  frequency)
          VALUES (@pres_drug5_order_id, @pres_drug_name5_concept_id, pres_dosage5, pres_dosage5, pres_frequency5);
        END IF;    #--5  
      ELSE #--1
        #--implement dispensation without prescription
        IF NOT ISNULL(dispensed_drug_name5) THEN
           IF ( dispensed_drug_name5 = pres_drug_name5 ) THEN
              select dispensed_drug_name5, old_enc_idbbc news;
           ELSEIF ( dispensed_drug_name5 = pres_drug_name4 ) THEN
                select dispensed_drug_name5, old_enc_id;
           ELSEIF ( dispensed_drug_name5 = pres_drug_name5 ) THEN
                  select dispensed_drug_name5, old_enc_id;
           ELSEIF ( dispensed_drug_name5 =  pres_drug_name5) THEN
                  select dispensed_drug_name5, old_enc_id;
           ELSEIF ( dispensed_drug_name5 =  pres_drug_name1) THEN
              select dispensed_drug_name3, old_enc_id;
           ELSE
        #create dispensing encounter
        SET @dispensing_encounter_type_id = (SELECT encounter_type_id FROM encounter_type 
                                             WHERE name = "DISPENSING"  LIMIT 1);
                                             
        SET @old_dispensing_encounter_id = COALESCE((SELECT encounter_id FROM encounter
                                                     WHERE encounter_id = old_enc_id
                                                     AND encounter_type = 25),0);
       
        IF (@old_dispensing_encounter_id = 0) THEN #--onee
          INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
          VALUES (old_enc_id, @dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, (SELECT UUID())) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

          SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());

          IF NOT ISNULL(prescription_duration) THEN #--11
            SET @auto_expire_date = NULL;
            SET @auto_expire_date = (SELECT
                  CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                    ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                  ELSE
                    ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                  END AS prescription_duration_in_days);
          ELSE
            SET @auto_expire_date = NULL;
          END IF; #--11
          
          INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
          VALUES (1, @dispensed_drug_name5_new_concept_id, 1, @dispensing_without_pres_encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, (SELECT UUID()));

          SET @dispensed_without_pres_drug_order_id = (SELECT LAST_INSERT_ID());

          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name5_concept_id, dispensed_dosage5, pres_dosage5, pres_frequency5, dispensed_quantity5);

          #create amount dispensed obs
          INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name5_concept_id, dispensed_quantity5,@creator, date_created, (SELECT UUID()));
        
          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                               WHERE concept_set = @arv_regimen_concept_id
                                               AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));
         END IF; #--7
        
        ELSE #--onee
          SET @old_temp_encounter_id = COALESCE((SELECT encounter_id FROM temp_encounter tnc
                                                 WHERE tnc.patient_id = patient_id
                                                 AND tnc.encounter_type = 54
                                                 AND tnc.encounter_datetime = encounter_datetime
                                                 LIMIT 1), 0 );
          
          IF (@old_temp_encounter_id = 0) THEN
            INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
            VALUES (@dispensing_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, (SELECT UUID()));
            SET @dispensing_without_pres_encounter_id = (SELECT LAST_INSERT_ID());
          ELSE
            SET @dispensing_without_pres_encounter_id = (@old_temp_encounter_id);
          END IF;

          IF NOT ISNULL(prescription_duration) THEN #--11
            SET @auto_expire_date = NULL;
            SET @auto_expire_date = (SELECT
                    CASE WHEN TRIM(REPLACE(SUBSTRING(prescription_duration,INSTR(prescription_duration, ' ')),'s','')) = 'Month' THEN
                      ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 30) - 2))
                    ELSE
                      ADDDATE(encounter_datetime,((LEFT(prescription_duration,INSTR(prescription_duration, ' ')) * 7) - 2))
                    END AS prescription_duration_in_days);
          ELSE
            SET @auto_expire_date = NULL;
          END IF; #--11
          
          INSERT INTO orders (order_type_id, concept_id, orderer, encounter_id, patient_id, start_date, auto_expire_date, creator, date_created, uuid)
          VALUES (1, @dispensed_drug_name5_new_concept_id, 1, @dispensing_without_pres_encounter_id, patient_id, encounter_datetime, @auto_expire_date, @creator,  date_created, (SELECT UUID()));
          
          SET @dispensed_without_pres_drug_order_id = (SELECT LAST_INSERT_ID());
          
          #create drug_order without quantity
          INSERT INTO drug_order (order_id, drug_inventory_id, equivalent_daily_dose, dose, frequency, quantity)
          VALUES (@dispensed_without_pres_drug_order_id, @dispensed_drug_name5_concept_id, dispensed_dosage5, dispensed_dosage5, pres_frequency5, dispensed_quantity5);

          #create amount dispensed obs
          INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_drug, value_numeric, creator, date_created, uuid)
          VALUES (patient_id, @amount_dispensed_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @dispensed_drug_name5_concept_id, dispensed_quantity5,@creator, date_created, (SELECT UUID()));

          SET @drug_concept_id = (SELECT concept_id FROM drug WHERE drug_id = @dispensed_drug_name5_concept_id);

          SET @arv_drug_concept_id = COALESCE((SELECT concept_id FROM concept_set
                                               WHERE concept_set = @arv_regimen_concept_id
                                               AND concept_id = @drug_concept_id), 0);

          IF (@arv_drug_concept_id != 0) THEN  #--7
            #create arv_regimen_received_abstracted_construct obs
            INSERT INTO temp_obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, uuid)
            VALUES (patient_id, @arv_regimens_received_abstracted_construct_concept_id, @dispensing_without_pres_encounter_id, @dispensed_without_pres_drug_order_id, encounter_datetime, @drug_concept_id, @creator, date_created, (SELECT UUID()));

         END IF; #--7 
        END IF; #--onee
       END IF;
      END IF;
      END IF;
#--   END IF;
#--------------------------------------------------------------------------------------------------------------------------------------------------     
     SET @arv_regimen_concept_id = ( SELECT concept_name.concept_id FROM concept_name
                                      LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                      WHERE name = "Antiretroviral drugs" AND voided = 0 AND retired = 0 LIMIT 1);
      
     #-- creating a regimen category encounter
     SET @regimen_category_treatment_encounter = ( SELECT e.encounter_id 
                                                    FROM encounter e
                                                      LEFT OUTER JOIN orders o ON e.encounter_id = o.encounter_id
                                                    WHERE e.encounter_datetime = encounter_datetime 
                                                    AND o.concept_id IN (SELECT concept_id
                                                                         FROM concept_set
                                                                         WHERE concept_set = @arv_regimen_concept_id)
                                                    AND e.encounter_type = 25
                                                    AND o.patient_id = patient_id
                                                    LIMIT 1);

    SET @dispensing_encounter_in_enc =  COALESCE(( SELECT e.encounter_id FROM encounter e
                                          WHERE e.encounter_datetime = encounter_datetime
                                          AND e.encounter_type = 54
                                          AND e.encounter_id = old_enc_id
                                          AND e.patient_id = patient_id LIMIT 1), 0);

    SET @dispensing_encounter_in_temp = COALESCE(( SELECT e.encounter_id FROM temp_encounter e
                                          WHERE e.encounter_datetime = encounter_datetime
                                          AND e.encounter_type = 54
                                          AND e.patient_id = patient_id LIMIT 1), 0);

   IF (@dispensing_encounter_in_enc = 0) THEN
      SET @dispense_encounter_id = (@dispensing_encounter_in_temp);
    ELSE
      SET @dispense_encounter_id = (@dispensing_encounter_in_enc);
    END IF;

    SET @regimen_category_dispensing_encounter = (SELECT e.encounter_id 
                                                    FROM temp_encounter e
                                                     LEFT OUTER JOIN orders o ON e.encounter_id = o.encounter_id
                                                    WHERE e.encounter_datetime = encounter_datetime 
                                                    AND o.concept_id IN (SELECT concept_id
                                                                         FROM concept_set
                                                                         WHERE concept_set = @arv_regimen_concept_id)
                                                    AND e.encounter_type = 54
                                                    AND o.patient_id = patient_id
                                                    LIMIT 1);

      IF (@regimen_category_treatment_encounter != 0) THEN
        #--create regimen_category observation mapped to treatment encounter
        INSERT INTO obs (person_id, concept_id, encounter_id,  obs_datetime, value_text, creator, date_created, uuid)
        VALUES (patient_id, @regimen_category_concept_id, @regimen_category_treatment_encounter, encounter_datetime, regimen_category, @creator, date_created, (SELECT UUID()));
      END IF;

      #--create regimen_category observation mapped to dispensing encounter
      INSERT INTO temp_obs (person_id, concept_id, encounter_id,  obs_datetime, value_text, creator, date_created, uuid)
      VALUES (patient_id, @regimen_category_concept_id, @dispense_encounter_id, encounter_datetime, regimen_category, @creator, date_created, (SELECT UUID()));
#--------------------------------------------------------------------------------------------------------------------------------------------------
  IF NOT ISNULL(appointment_date) THEN
    SET @appointment_date_concept_id = (SELECT concept_id FROM concept_name WHERE name = 'Appointment date' LIMIT 1);
    SET @appointment_encounter_type_id = (SELECT encounter_type_id FROM encounter_type WHERE name = 'APPOINTMENT' LIMIT 1);

    SET @appointment_date_uuid = (SELECT uuid());

    INSERT INTO temp_encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
    VALUES (@appointment_encounter_type_id, patient_id, @provider, encounter_datetime, @creator, date_created, @appointment_date_uuid) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id, voided = 0;

    SET @appointment_encounter_id = (SELECT encounter_id FROM temp_encounter WHERE uuid = @appointment_date_uuid);

    INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator, date_created, uuid)
    VALUES (patient_id, @appointment_date_concept_id, @appointment_encounter_id, encounter_datetime, appointment_date, @creator, date_created, (SELECT UUID()));

  END IF;
#-----------------------------------------------------------------------------------------------------------------------------    
    END LOOP;

    # SET UNIQUE_CHECKS = 1;
    # SET FOREIGN_KEY_CHECKS = 1;
    # COMMIT;
    # SET AUTOCOMMIT = 1;

END$$

DELIMITER ;
