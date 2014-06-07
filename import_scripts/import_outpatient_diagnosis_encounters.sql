# This procedure imports data from `bart1_intermediate_bare_bones` to `migration_database`

# The default DELIMITER is disabled to avoid conflicting with our scripts
DELIMITER $$

# Check if a similar procedure exists and drop it so we can start from a clean slate
DROP PROCEDURE IF EXISTS `proc_import_outpatient_diagnosis_encounters`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_import_outpatient_diagnosis_encounters`(
IN in_patient_id INT(11)
)
BEGIN


	# Declare condition for exiting loop
	DECLARE done INT DEFAULT FALSE;

	DECLARE id int(11);
	DECLARE visit_encounter_id int(11);
	DECLARE old_enc_id int(11);
	DECLARE patient_id int(11);
	DECLARE refer_to_anotha_hosp varchar(255);
	DECLARE pri_diagnosis varchar(255);
	DECLARE sec_diagnosis varchar(255);
	DECLARE treatment1 varchar(255);
	DECLARE treatment2 varchar(255);
	DECLARE treatment3 varchar(255);
	DECLARE treatment4 varchar(255);
	DECLARE treatment5 varchar(255);
	DECLARE location varchar(255);
	DECLARE voided tinyint(1);
	DECLARE void_reason varchar(255);
	DECLARE date_voided date;
	DECLARE voided_by int(11);
	DECLARE encounter_datetime datetime;	
	DECLARE date_created datetime;
	DECLARE creator varchar(255);
	DECLARE visit_date DATE;

	# Declare and initialise cursor for looping through the table
DECLARE cur CURSOR FOR SELECT DISTINCT `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`id`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`visit_encounter_id`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`old_enc_id`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`patient_id`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`refer_to_anotha_hosp`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`pri_diagnosis`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`sec_diagnosis`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`treatment1`,
`bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`treatment2`,
`bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`treatment3`,
`bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`treatment4`,
`bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`treatment5`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`location`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`voided`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`void_reason`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`date_voided`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`voided_by`,
`bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`encounter_datetime`, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`date_created`,   `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`creator`, COALESCE(`bart1_intermediate_bare_bones`.`visit_encounters`.visit_date, `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.date_created) FROM `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters` LEFT OUTER JOIN `bart1_intermediate_bare_bones`.`visit_encounters` ON
        visit_encounter_id = `bart1_intermediate_bare_bones`.`visit_encounters`.`id`
       WHERE `bart1_intermediate_bare_bones`.`outpatient_diagnosis_encounters`.`patient_id` = in_patient_id;

	# Declare loop position check
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

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
			refer_to_anotha_hosp,
			pri_diagnosis,
			sec_diagnosis,
			treatment1,
			treatment2,
			treatment3,
			treatment4,
			treatment5,						
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

	  # Get location id
	  SET @location_id = (SELECT location_id FROM location WHERE name = location LIMIT 1);
    
    # Get id of encounter type
	  SET @encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'outpatient diagnosis' LIMIT 1);

	  # Create outpatient_reception_encounter
	  INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, location_id, encounter_datetime, creator, date_created, uuid) VALUES (old_enc_id, @encounter_type, patient_id, @provider, @location_id, encounter_datetime, @creator, date_created, (SELECT UUID())) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;
              
          # Check if the field is not empty
          IF ISNULL(refer_to_anotha_hosp) THEN
              # Get concept_id
              SET @refer_to_anotha_hosp_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'Refer to other hospital' AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded id
              SET @refer_to_anotha_hosp_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'NO' AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded_name_id
              SET @refer_to_anotha_hosp_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'NO' AND voided = 0 AND retired = 0 LIMIT 1);

              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
              VALUES (patient_id, @refer_to_anotha_hosp_concept_id, old_enc_id, encounter_datetime, @location_id , @refer_to_anotha_hosp_value_coded, @refer_to_anotha_hosp_value_coded_name_id, @creator, date_created, (SELECT UUID()));
           
           # Get last obs id for association later to other records
           SET @refer_to_anotha_hosp_id = (SELECT LAST_INSERT_ID());
          ELSE
              # Get concept_id
              SET @refer_to_anotha_hosp_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'Refer to other hospital' AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded id
              SET @refer_to_anotha_hosp_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = refer_to_anotha_hosp AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded_name_id
              SET @refer_to_anotha_hosp_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = refer_to_anotha_hosp AND voided = 0 AND retired = 0 LIMIT 1);

              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
              VALUES (patient_id, @refer_to_anotha_hosp_concept_id, old_enc_id, encounter_datetime, @location_id , @refer_to_anotha_hosp_value_coded, @refer_to_anotha_hosp_value_coded_name_id, @creator, date_created, (SELECT UUID()));
            
            # Get last obs id for association later to other records
            SET @refer_to_anotha_hosp_id = (SELECT LAST_INSERT_ID());
           END IF;
           
  #------------------------------------------------------------------------------------------------------------------------------
          
          # Check if the field is not empty
          IF NOT ISNULL(pri_diagnosis) THEN
            IF (pri_diagnosis <> "Not applicable") THEN
              # Get concept_id
              SET @pri_diagnosis_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'Primary diagnosis' AND voided = 0 AND retired = 0 LIMIT 1);
              
              IF (pri_diagnosis = 'Fractures Clavicle') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Malleoral') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Metacarpals') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Metatarsal') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Spine') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Pelvis') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Femur') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Humerus') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Phalanges') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Radius/ulna') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Tibia/Fibula') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Open Fracture') THEN
                SET @pri_diagnosis_name = ('Fracture');
              ELSE
                # Get the correct diagnosis
                SET @pri_diagnosis_name = (SELECT bart_two_concept_name
                                           FROM concept_name_map
                                           WHERE bart_one_concept_name = pri_diagnosis
                                           LIMIT 1);
              END IF;

              IF ISNULL(@pri_diagnosis_name) THEN
                SET @bart2_primary_diagnosis_name = (pri_diagnosis);
              ELSE
                SET @bart2_primary_diagnosis_name = (@pri_diagnosis_name);
              END IF;

              # Get value_coded id
              SET @pri_diagnosis_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_primary_diagnosis_name AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded_name_id
              SET @pri_diagnosis_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_primary_diagnosis_name AND voided = 0 AND retired = 0 LIMIT 1);
              
              IF ISNULL(@pri_diagnosis_value_coded) THEN
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                VALUES (patient_id, @pri_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @bart2_primary_diagnosis_name, @creator, date_created, (SELECT UUID()));
              ELSE
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
                VALUES (patient_id, @pri_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @pri_diagnosis_value_coded, @pri_diagnosis_value_coded_name_id, @creator, date_created, (SELECT UUID()));
              END IF;

              # creating a detailed primary diagnosis
              SET @detailed_primary_diagnosis_concept_id = (SELECT concept_name.concept_id FROM concept_name
                            LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                            WHERE name = "Detailed primary diagnosis" AND voided = 0 AND retired = 0 LIMIT 1);
              
              IF (pri_diagnosis = "Diarrhoea disease(non-bloody)") THEN
                # Create detailed_primary_diagnosis_observation
                
                  SET @detailed_pri_diag = (SELECT concept_name.concept_id FROM concept_name
                            LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                            WHERE name = 'non-bloody' AND voided = 0 AND retired = 0 LIMIT 1);
                  
                  IF ISNULL (@detailed_pri_diag) THEN
                    INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                    VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'non-bloody', @creator, date_created, (SELECT UUID()));
                  ELSE
                    INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                    VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @detailed_pri_diag, @creator, date_created, (SELECT UUID()));
                  END IF;

              ELSEIF (pri_diagnosis = "Sprains (Joint Soft Tissue Injury)") THEN
                  SET @bart_two_sprains_name = (SELECT bart_two_concept_name FROM concept_name_map WHERE bart_one_concept_name = "Sprains" LIMIT 1);

                  SET @detailed_diagnosis_name_concept_id = (SELECT concept_name.concept_id FROM concept_name
                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = @bart_two_sprains_name AND voided = 0 AND retired = 0 LIMIT 1);
                  
                  SET @detailed_diagnosis_name_concept_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = @bart_two_sprains_name AND voided = 0 AND retired = 0 LIMIT 1);
                  
                  # Create _detailed_primary_diagnosis_observation
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @detailed_diagnosis_name_concept_id, @detailed_diagnosis_name_concept_name_id, @creator, date_created, (SELECT UUID()));
               
               ELSEIF (pri_diagnosis = "Soft Tissue Injury (Excluding Joints)") THEN
                   # Create detailed_primary_diagnosis_observation
                   
                   SET @detailed_sec_diag3 = (SELECT concept_name.concept_id FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                            WHERE name = 'Excluding Joints' AND voided = 0 AND retired = 0 LIMIT 1);
                  
                    IF ISNULL (@detailed_sec_diag3) THEN
                      INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                      VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Excluding Joints', @creator, date_created, (SELECT UUID()));
                    ELSE
                      INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                      VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @detailed_sec_diag3, @creator, date_created, (SELECT UUID()));
                    END IF;

              ELSEIF (pri_diagnosis = 'Fractures Clavicle') THEN
                SET @fracture_1_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Clavicle'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_1_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Clavicle', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_1_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Malleoral') THEN
                SET @fracture_2_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Malleolar'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_2_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Malleolar', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_2_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Metacarpals') THEN
                SET @fracture_3_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Metacarpal'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

               IF ISNULL (@fracture_3_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Metacarpal', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_3_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Metatarsal') THEN
                SET @fracture_4_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Metatarsal'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_4_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Metatarsal', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_4_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Spine') THEN
                SET @fracture_5_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Spine'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_5_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Spine', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_5_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Pelvis') THEN
                SET @fracture_6_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Pelvis'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_6_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Pelvis', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_6_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Femur') THEN
                SET @fracture_7_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Femur'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_7_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Femur', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_7_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Humerus') THEN
                SET @fracture_8_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Humerus'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_8_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Humerus', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_8_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Phalanges') THEN
                SET @fracture_9_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Phalanges'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_9_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Phalanges', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_9_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Radius/ulna') THEN
                SET @fracture_10_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Radius/ulna'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);
 
                IF ISNULL (@fracture_10_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Radius/ulna', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_10_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Fractures Tibia/Fibula') THEN
                SET @fracture_11_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Tibia/Fibula'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_11_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Tibia/Fibula', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_11_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (pri_diagnosis = 'Open Fracture') THEN
                SET @fracture_12_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Open Fracture'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_12_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Open Fracture', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_primary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_12_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              END IF;

              # Get last obs id for association later to other records
              SET @pri_diagnosis_id = (SELECT LAST_INSERT_ID());
            END IF;
          END IF;
  #------------------------------------------------------------------------------------------------------------------------------

          # Check if the field is not empty
          IF NOT ISNULL(sec_diagnosis) THEN
            IF (sec_diagnosis <> "Not applicable") THEN
              # Get concept_id
              SET @sec_diagnosis_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'Secondary diagnosis' AND voided = 0 AND retired = 0 LIMIT 1);

              IF (sec_diagnosis = 'Fractures Clavicle') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Malleoral') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Metacarpals') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Metatarsal') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Spine') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Pelvis') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Femur') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Humerus') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Phalanges') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Radius/ulna') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Fractures Tibia/Fibula') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSEIF (pri_diagnosis = 'Open Fracture') THEN
                SET @sec_diagnosis_name = ('Fracture');
              ELSE
                # Get the correct secondary diagnosis name
                SET @sec_diagnosis_name = (SELECT bart_two_concept_name 
                                           FROM concept_name_map 
                                           WHERE bart_one_concept_name = sec_diagnosis 
                                           LIMIT 1);
              END IF;

              IF ISNULL(@sec_diagnosis_name) THEN
                SET @bart2_secondary_diagnosis_name = (sec_diagnosis);
              ELSE
                SET @bart2_secondary_diagnosis_name = (@sec_diagnosis_name);
              END IF;

              # Get value_coded id
              SET @sec_diagnosis_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_secondary_diagnosis_name AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded_name_id
              SET @sec_diagnosis_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_secondary_diagnosis_name AND voided = 0 AND retired = 0 LIMIT 1);

              IF ISNULL(@sec_diagnosis_value_coded) THEN
                # Create observation with drug_name as value_text
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                VALUES (patient_id, @sec_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @bart2_secondary_diagnosis_name, @creator, date_created, (SELECT UUID()));
              ELSE
                # Create observation with drug_name as value_coded
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
                VALUES (patient_id, @sec_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @sec_diagnosis_value_coded, @sec_diagnosis_value_coded_name_id, @creator, date_created, (SELECT UUID()));
              END IF;
              
              # creating a detailed secondary diagnosis
              SET @detailed_secondary_diagnosis_concept_id = (SELECT concept_name.concept_id FROM concept_name
                            LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                            WHERE name = "Detailed secondary diagnosis" AND voided = 0 AND retired = 0 LIMIT 1);
              
              IF (sec_diagnosis = "Diarrhoea disease(non-bloody)") THEN
                # Create detailed_secondary_diagnosis_observation

                  SET @detailed_sec_diag = (SELECT concept_name.concept_id FROM concept_name
                            LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                            WHERE name = 'non-bloody' AND voided = 0 AND retired = 0 LIMIT 1);
                  
                  IF ISNULL (@detailed_sec_diag) THEN
                    INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                    VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'non-bloody', @creator, date_created, (SELECT UUID()));
                  ELSE
                    INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                    VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @detailed_sec_diag, @creator, date_created, (SELECT UUID()));
                  END IF;
             
              ELSEIF (sec_diagnosis = "Sprains (Joint Soft Tissue Injury)") THEN
                SET @bart_two_sprains_name = (SELECT bart_two_concept_name FROM concept_name_map WHERE bart_one_concept_name = "Sprains" LIMIT 1);
                
                SET @detailed_diagnosis_name_concept_id = (SELECT concept_name.concept_id FROM concept_name
                            LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                            WHERE name = @bart_two_sprains_name  AND voided = 0 AND retired = 0 LIMIT 1);
                
                SET @detailed_diagnosis_name_concept_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                            LEFT OUTER JOIN concept ON concept_name.concept_id = concept.concept_id 
                            WHERE name = @bart_two_sprains_name  AND voided = 0 AND retired = 0 LIMIT 1);
                
                # Create observation with drug_name as value_coded
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
                VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @detailed_diagnosis_name_concept_id, @detailed_diagnosis_name_concept_name_id, @creator, date_created, (SELECT UUID()));
                
              ELSEIF (sec_diagnosis = "Soft Tissue Injury (Excluding Joints)") THEN
                   # Create detailed_secondary_diagnosis_observation
                SET @detailed_sec_diag2 = (SELECT concept_name.concept_id FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                            WHERE name = 'Excluding Joints' AND voided = 0 AND retired = 0 LIMIT 1);
                  
                  IF ISNULL (@detailed_sec_diag2) THEN
                    INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                    VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Excluding Joints', @creator, date_created, (SELECT UUID()));
                  ELSE
                    INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                    VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @detailed_sec_diag2, @creator, date_created, (SELECT UUID()));
                  END IF;

              ELSEIF (sec_diagnosis = 'Fractures Clavicle') THEN
                SET @fracture_1_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Clavicle'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);
                  
                IF ISNULL (@fracture_1_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Clavicle', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_1_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Fractures Malleoral') THEN
                SET @fracture_2_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Malleolar'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_2_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Malleolar', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_2_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Fractures Metacarpals') THEN
                SET @fracture_3_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Metacarpal'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

               IF ISNULL (@fracture_3_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Metacarpal', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_3_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Fractures Metatarsal') THEN
                SET @fracture_4_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Metatarsal'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_4_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Metatarsal', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_4_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Fractures Spine') THEN
                SET @fracture_5_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Spine'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_5_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Spine', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_5_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Fractures Pelvis') THEN
                SET @fracture_6_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Pelvis'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_6_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Pelvis', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_6_detailed, @creator, date_created, (SELECT UUID()));
                END IF;
             
              ELSEIF (sec_diagnosis = 'Fractures Femur') THEN
                SET @fracture_7_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Femur'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_7_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Femur', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_7_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Fractures Humerus') THEN
                SET @fracture_8_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Humerus'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_8_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Humerus', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_8_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Fractures Phalanges') THEN
                SET @fracture_9_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Phalanges'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_9_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Phalanges', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_9_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Fractures Radius/ulna') THEN
                SET @fracture_10_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Radius/ulna'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);
 
                IF ISNULL (@fracture_10_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Radius/ulna', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_10_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Fractures Tibia/Fibula') THEN
                SET @fracture_11_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Tibia/Fibula'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);

                IF ISNULL (@fracture_11_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Tibia/Fibula', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_11_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              ELSEIF (sec_diagnosis = 'Open Fracture') THEN
                SET @fracture_12_detailed = (SELECT concept_name.concept_id
                              FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                              WHERE name = 'Open Fracture'
                              AND voided = 0
                              AND retired = 0 LIMIT 1);
                              
                IF ISNULL (@fracture_12_detailed) THEN
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , 'Open Fracture', @creator, date_created, (SELECT UUID()));
                ELSE
                  INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, creator, date_created, uuid)
                  VALUES (patient_id, @detailed_secondary_diagnosis_concept_id, old_enc_id, encounter_datetime, @location_id , @fracture_12_detailed, @creator, date_created, (SELECT UUID()));
                END IF;

              END IF;
              
              # Get last obs id for association later to other records
              SET @sec_diagnosis_id = (SELECT LAST_INSERT_ID());
            
            END IF;
          END IF;
  #-----------------------------------------------------------------------------------------------------------------------------

          # Check if the field is not empty
          IF NOT ISNULL(treatment1) THEN

              # Get concept_id
              SET @treatment_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'Drugs dispensed' AND voided = 0 AND retired = 0 LIMIT 1);

              # get the correct drug_name spelling 
              SET @bart2_drug_name = (SELECT bart_two_concept_name FROM concept_name_map WHERE bart_one_concept_name = treatment1 LIMIT 1);

              IF ISNULL(@bart2_drug_name) THEN
                SET @bart2_drug_concept_name = (treatment1);
              ELSE
                SET @bart2_drug_concept_name = (@bart2_drug_name);
              END IF;

              # Get value_coded id
              SET @treatment_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded_name_id
              SET @treatment_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);
              
              IF ISNULL(@treatment_value_coded) THEN
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @bart2_drug_concept_name,  @creator, date_created, (SELECT UUID()));
              ELSE
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @treatment_value_coded, @treatment_value_coded_name_id, @creator, date_created, (SELECT UUID()));
              END IF;
              

              # Get last obs id for association later to other records
              SET @treatment_id = (SELECT LAST_INSERT_ID());

          END IF;
#--------------------------------------------------------------------------------------------------------------------------

          # Check if the field is not empty
          IF NOT ISNULL(treatment2) THEN

              # Get concept_id
              SET @treatment_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'Drugs dispensed' AND voided = 0 AND retired = 0 LIMIT 1);

              # get the correct drug_name spelling 
              SET @bart2_drug_name = (SELECT bart_two_concept_name FROM concept_name_map WHERE bart_one_concept_name = treatment2 LIMIT 1);

              IF ISNULL(@bart2_drug_name) THEN
                SET @bart2_drug_concept_name = (treatment2);
              ELSE
                SET @bart2_drug_concept_name = (@bart2_drug_name);
              END IF;

              # Get value_coded id
              SET @treatment_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded_name_id
              SET @treatment_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);
              
              IF ISNULL(@treatment_value_coded) THEN
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @bart2_drug_concept_name,  @creator, date_created, (SELECT UUID()));
              ELSE
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @treatment_value_coded, @treatment_value_coded_name_id, @creator, date_created, (SELECT UUID()));
              END IF;
              

              # Get last obs id for association later to other records
              SET @treatment_id = (SELECT LAST_INSERT_ID());

          END IF;
#---------------------------------------------------------------------------------------------------------------------------

          # Check if the field is not empty
          IF NOT ISNULL(treatment3) THEN

              # Get concept_id
              SET @treatment_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'Drugs dispensed' AND voided = 0 AND retired = 0 LIMIT 1);

              # get the correct drug_name spelling 
              SET @bart2_drug_name = (SELECT bart_two_concept_name FROM concept_name_map WHERE bart_one_concept_name = treatment3 LIMIT 1);

              IF ISNULL(@bart2_drug_name) THEN
                SET @bart2_drug_concept_name = (treatment3);
              ELSE
                SET @bart2_drug_concept_name = (@bart2_drug_name);
              END IF;

              # Get value_coded id
              SET @treatment_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded_name_id
              SET @treatment_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);
              
              IF ISNULL(@treatment_value_coded) THEN
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @bart2_drug_concept_name,  @creator, date_created, (SELECT UUID()));
              ELSE
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @treatment_value_coded, @treatment_value_coded_name_id, @creator, date_created, (SELECT UUID()));
              END IF;
              

              # Get last obs id for association later to other records
              SET @treatment_id = (SELECT LAST_INSERT_ID());

          END IF;
#----------------------------------------------------------------------------------------------------------------------------

          # Check if the field is not empty
          IF NOT ISNULL(treatment4) THEN

              # Get concept_id
              SET @treatment_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'Drugs dispensed' AND voided = 0 AND retired = 0 LIMIT 1);

              # get the correct drug_name spelling 
              SET @bart2_drug_name = (SELECT bart_two_concept_name FROM concept_name_map WHERE bart_one_concept_name = treatment4 LIMIT 1);

              IF ISNULL(@bart2_drug_name) THEN
                SET @bart2_drug_concept_name = (treatment4);
              ELSE
                SET @bart2_drug_concept_name = (@bart2_drug_name);
              END IF;

              # Get value_coded id
              SET @treatment_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded_name_id
              SET @treatment_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);
              
              IF ISNULL(@treatment_value_coded) THEN
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @bart2_drug_concept_name,  @creator, date_created, (SELECT UUID()));
              ELSE
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @treatment_value_coded, @treatment_value_coded_name_id, @creator, date_created, (SELECT UUID()));
              END IF;
              

              # Get last obs id for association later to other records
              SET @treatment_id = (SELECT LAST_INSERT_ID());

          END IF;
#----------------------------------------------------------------------------------------------------------------------------

          # Check if the field is not empty
          IF NOT ISNULL(treatment5) THEN

              # Get concept_id
              SET @treatment_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = 'Drugs dispensed' AND voided = 0 AND retired = 0 LIMIT 1);

              # get the correct drug_name spelling 
              SET @bart2_drug_name = (SELECT bart_two_concept_name FROM concept_name_map WHERE bart_one_concept_name = treatment5 LIMIT 1);

              IF ISNULL(@bart2_drug_name) THEN
                SET @bart2_drug_concept_name = (treatment5);
              ELSE
                SET @bart2_drug_concept_name = (@bart2_drug_name);
              END IF;

              # Get value_coded id
              SET @treatment_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);

              # Get value_coded_name_id
              SET @treatment_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                          LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                          WHERE name = @bart2_drug_concept_name AND voided = 0 AND retired = 0 LIMIT 1);

              IF ISNULL(@treatment_value_coded) THEN
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @bart2_drug_concept_name,  @creator, date_created, (SELECT UUID()));
              ELSE
                # Create observation
                INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
                VALUES (patient_id, @treatment_concept_id, old_enc_id, encounter_datetime, @location_id , @treatment_value_coded, @treatment_value_coded_name_id, @creator, date_created, (SELECT UUID()));
              END IF;

              # Get last obs id for association later to other records
              SET @treatment_id = (SELECT LAST_INSERT_ID());

          END IF;
#----------------------------------------------------------------------------------------------------------------------------
	END LOOP;

END$$

DELIMITER ;
