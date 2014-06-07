# This procedure imports data from `bart1_intermediate_bare_bones` to `migration_database`

# The default DELIMITER is disabled to avoid conflicting with our scripts
DELIMITER $$

# Check if a similar procedure exists and drop it so we can start from a clean slate
DROP PROCEDURE IF EXISTS `proc_import_vitals_encounters`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_import_vitals_encounters`(
	IN in_patient_id INT(11)
)
BEGIN


	# Declare condition for exiting loop
	DECLARE done INT DEFAULT FALSE;

	DECLARE id int(11);
	DECLARE visit_encounter_id int(11);
	DECLARE old_enc_id int(11);
	DECLARE patient_id int(11);
	DECLARE weight float;
	DECLARE height float;
	DECLARE bmi float;
	DECLARE weight_for_age float;
	DECLARE height_for_age float;
	DECLARE weight_for_height float;
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
DECLARE cur CURSOR FOR SELECT DISTINCT `bart1_intermediate_bare_bones`.`vitals_encounters`.`id`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`visit_encounter_id`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`old_enc_id`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`patient_id`,      `bart1_intermediate_bare_bones`.`vitals_encounters`.`weight`,     `bart1_intermediate_bare_bones`.`vitals_encounters`.`height`,           `bart1_intermediate_bare_bones`.`vitals_encounters`.`bmi`,    `bart1_intermediate_bare_bones`.`vitals_encounters`.`weight_for_age`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`height_for_age`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`weight_for_height`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`location`,        `bart1_intermediate_bare_bones`.`vitals_encounters`.`voided`,     `bart1_intermediate_bare_bones`.`vitals_encounters`.`void_reason`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`date_voided`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`voided_by`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`encounter_datetime`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`date_created`, `bart1_intermediate_bare_bones`.`vitals_encounters`.`creator`, COALESCE(`bart1_intermediate_bare_bones`.`visit_encounters`.visit_date, `bart1_intermediate_bare_bones`.`vitals_encounters`.date_created) FROM `bart1_intermediate_bare_bones`.`vitals_encounters` LEFT OUTER JOIN `bart1_intermediate_bare_bones`.`visit_encounters` ON
        visit_encounter_id = `bart1_intermediate_bare_bones`.`visit_encounters`.`id`
        WHERE `bart1_intermediate_bare_bones`.`vitals_encounters`.`patient_id` = in_patient_id;

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
			weight,
			height,
			bmi,
			weight_for_age,
			height_for_age,
			weight_for_height,
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

  #--SET @migrated_encounter_id = COALESCE((SELECT encounter_id FROM bart2_development.encounter
  #--                              WHERE encounter_id = old_enc_id AND voided = 0), 0);
  #--IF @migrated_encounter_id = 0 THEN

	# Map destination user to source user
	SET @creator = COALESCE((SELECT user_id FROM users WHERE username = creator), 1);

	# Map destination user to source user
	SET @provider = COALESCE((SELECT person_id FROM users WHERE user_id = @creator), 1);

	# Get location id
	SET @location_id = (SELECT location_id FROM location WHERE name = location);

	# Get id of encounter type
	SET @encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'vitals');

	# Create encounter
	INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, location_id, encounter_datetime, creator, date_created, uuid) VALUES (old_enc_id, @encounter_type, patient_id, @provider, @location_id, encounter_datetime, @creator, date_created, (SELECT UUID())) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

	
        # Check if the field is not empty
        IF NOT ISNULL(weight) THEN

            # Get concept_id
            SET @weight_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Weight (kg)' AND voided = 0 AND retired = 0 LIMIT 1);
          IF (weight = 'Unknown') THEN
            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
            VALUES (patient_id, @weight_concept_id, old_enc_id, encounter_datetime, @location_id , weight, @creator, date_created, (SELECT UUID()));
          ELSE
            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_numeric, creator, date_created, uuid)
            VALUES (patient_id, @weight_concept_id, old_enc_id, encounter_datetime, @location_id , ROUND(weight,1), @creator, date_created, (SELECT UUID()));
          END IF;

            # Get last obs id for association later to other records
            SET @weight_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(height) THEN

            # Get concept_id
            SET @height_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Height (cm)' AND voided = 0 AND retired = 0 LIMIT 1);
          IF (height = 'Unknown') THEN
            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
            VALUES (patient_id, @height_concept_id, old_enc_id, encounter_datetime, @location_id , height, @creator, date_created, (SELECT UUID()));
          ELSE
            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_numeric, creator, date_created, uuid)
            VALUES (patient_id, @height_concept_id, old_enc_id, encounter_datetime, @location_id , ROUND(height,1), @creator, date_created, (SELECT UUID()));
          END IF;


            # Get last obs id for association later to other records
            SET @height_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(bmi) THEN

            # Get concept_id
            SET @bmi_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Body mass index, measured' AND voided = 0 AND retired = 0 LIMIT 1);

            IF (bmi = 'Unknown') THEN
              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
              VALUES (patient_id, @bmi_concept_id, old_enc_id, encounter_datetime, @location_id , bmi, @creator, date_created, (SELECT UUID()));
            ELSE
               # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_numeric, creator, date_created, uuid)
              VALUES (patient_id, @bmi_concept_id, old_enc_id, encounter_datetime, @location_id , ROUND(bmi,1), @creator, date_created, (SELECT UUID()));
            END IF;


            # Get last obs id for association later to other records
            SET @bmi_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(weight_for_age) THEN

            # Get concept_id
            SET @weight_for_age_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Weight for age percent of median' AND voided = 0 AND retired = 0 LIMIT 1);
    
            IF (weight_for_age = 'Unknown') THEN
              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
              VALUES (patient_id, @weight_for_age_concept_id, old_enc_id, encounter_datetime, @location_id , weight_for_age, @creator, date_created, (SELECT UUID()));
            ELSE
              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
              VALUES (patient_id, @weight_for_age_concept_id, old_enc_id, encounter_datetime, @location_id , weight_for_age, @creator, date_created, (SELECT UUID()));
            END IF;

            # Get last obs id for association later to other records
            SET @weight_for_age_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(height_for_age) THEN

            # Get concept_id
            SET @height_for_age_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Height for age percent of median' AND voided = 0 AND retired = 0 LIMIT 1);

            IF (height_for_age = 'Unknown') THEN
              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
              VALUES (patient_id, @height_for_age_concept_id, old_enc_id, encounter_datetime, @location_id , height_for_age, @creator, date_created, (SELECT UUID()));
            ELSE
              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_numeric, creator, date_created, uuid)
              VALUES (patient_id, @height_for_age_concept_id, old_enc_id, encounter_datetime, @location_id , height_for_age, @creator, date_created, (SELECT UUID()));
            END IF;
            

            # Get last obs id for association later to other records
            SET @height_for_age_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(weight_for_height) THEN

            # Get concept_id
            SET @weight_for_height_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Weight for height percent of median' AND voided = 0 AND retired = 0 LIMIT 1);
            IF (weight_for_height = 'Unknown') THEN
              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
              VALUES (patient_id, @weight_for_height_concept_id, old_enc_id, encounter_datetime, @location_id , weight_for_height, @creator, date_created, (SELECT UUID()));
            ELSE
              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_numeric, creator, date_created, uuid)
              VALUES (patient_id, @weight_for_height_concept_id, old_enc_id, encounter_datetime, @location_id , weight_for_height, @creator, date_created, (SELECT UUID()));
            END IF;
            

            # Get last obs id for association later to other records
            SET @weight_for_height_id = (SELECT LAST_INSERT_ID());

        END IF;

             
	END LOOP;

END$$

DELIMITER ;
