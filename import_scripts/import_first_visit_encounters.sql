# This procedure imports data from `bart1_intermediate_bare_bones` to `bart2`

# The default DELIMITER is disabled to avoid conflicting with our scripts
DELIMITER $$

# Check if a similar procedure exists and drop it so we can start from a clean slate
DROP PROCEDURE IF EXISTS `proc_import_first_visit_encounters`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_import_first_visit_encounters`(
IN in_patient_id INT(11)
)

BEGIN

	# Declare condition for exiting loop
	DECLARE done INT DEFAULT FALSE;

	DECLARE id int(11);
	DECLARE visit_encounter_id int(11);
	DECLARE old_enc_id int(11);
	DECLARE patient_id int(11);
	DECLARE agrees_to_follow_up varchar(40);
	DECLARE date_of_hiv_pos_test date;
	DECLARE date_of_hiv_pos_test_estimated tinyint(1);
	DECLARE location_of_hiv_pos_test varchar(255);
	DECLARE arv_number_at_that_site varchar(255);
	DECLARE location_of_art_initiation varchar(255);
	DECLARE taken_arvs_in_last_two_months varchar(255);
	DECLARE taken_arvs_in_last_two_weeks varchar(255);
	DECLARE has_transfer_letter varchar(255);
	DECLARE site_transferred_from varchar(255);
	DECLARE date_of_art_initiation date;
	DECLARE ever_registered_at_art varchar(25);
	DECLARE ever_received_arv varchar(25);
	DECLARE last_arv_regimen varchar(255);
	DECLARE date_last_arv_taken date;
	DECLARE date_last_arv_taken_estimated date;
	DECLARE weight float;
	DECLARE height float;
	DECLARE bmi float;
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
DECLARE cur CURSOR FOR SELECT DISTINCT `bart1_intermediate_bare_bones`.`first_visit_encounters`.`id`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`visit_encounter_id`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`old_enc_id`, 
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`patient_id`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`agrees_to_follow_up`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`date_of_hiv_pos_test`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`date_of_hiv_pos_test_estimated`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`location_of_hiv_pos_test`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`arv_number_at_that_site`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`location_of_art_initiation`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`taken_arvs_in_last_two_months`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`taken_arvs_in_last_two_weeks`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`has_transfer_letter`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`site_transferred_from`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`date_of_art_initiation`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`ever_registered_at_art`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`ever_received_arv`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`last_arv_regimen`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`date_last_arv_taken`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`date_last_arv_taken_estimated`,
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`weight`,
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`height`,
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`bmi`, `bart1_intermediate_bare_bones`.`first_visit_encounters`.`location`, 
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`voided`, 
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`void_reason`, 
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`date_voided`, 
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`voided_by`, 
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`encounter_datetime`, 
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`date_created`, 
`bart1_intermediate_bare_bones`.`first_visit_encounters`.`creator`, COALESCE(`bart1_intermediate_bare_bones`.`visit_encounters`.visit_date, `bart1_intermediate_bare_bones`.`first_visit_encounters`.date_created) FROM `bart1_intermediate_bare_bones`.`first_visit_encounters` LEFT OUTER JOIN `bart1_intermediate_bare_bones`.`visit_encounters` ON
        visit_encounter_id = `bart1_intermediate_bare_bones`.`visit_encounters`.`id`
        WHERE `bart1_intermediate_bare_bones`.`first_visit_encounters`.`patient_id` = in_patient_id;

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
			agrees_to_follow_up,
			date_of_hiv_pos_test,
			date_of_hiv_pos_test_estimated,
			location_of_hiv_pos_test,
			arv_number_at_that_site,
			location_of_art_initiation,
			taken_arvs_in_last_two_months,
			taken_arvs_in_last_two_weeks,
			has_transfer_letter,
			site_transferred_from,
			date_of_art_initiation,
			ever_registered_at_art,
			ever_received_arv,
			last_arv_regimen,
			date_last_arv_taken,
			date_last_arv_taken_estimated,
			weight,
			height,
			bmi,
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
	SET @location_id = (SELECT location_id FROM location WHERE name = location);

	# Get id of encounter type
	SET @encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'HIV CLINIC REGISTRATION');

	# Create encounter
	INSERT INTO encounter (encounter_id, encounter_type, patient_id, provider_id, location_id, encounter_datetime, creator, date_created, uuid) VALUES (old_enc_id, @encounter_type, patient_id, @provider, @location_id, encounter_datetime, @creator, date_created, (SELECT UUID())) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

	
        # Check if the field is not empty
        IF NOT ISNULL(agrees_to_follow_up) THEN

            # Get concept_id
            SET @agrees_to_follow_up_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'agrees to followup' AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded id
            SET @agrees_to_follow_up_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = agrees_to_follow_up AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded_name_id
            SET @agrees_to_follow_up_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = agrees_to_follow_up AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
            VALUES (patient_id, @agrees_to_follow_up_concept_id, old_enc_id, encounter_datetime, @location_id , @agrees_to_follow_up_value_coded, @agrees_to_follow_up_value_coded_name_id, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @agrees_to_follow_up_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(date_of_hiv_pos_test) THEN

            # Get concept_id
            SET @date_of_hiv_pos_test_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'CONFIRMATORY HIV TEST DATE' AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_datetime, creator, date_created, uuid)
            VALUES (patient_id, @date_of_hiv_pos_test_concept_id, old_enc_id, encounter_datetime, @location_id , date_of_hiv_pos_test, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @date_of_hiv_pos_test_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(date_of_hiv_pos_test_estimated) THEN

            # Get concept_id
            SET @date_of_hiv_pos_test_estimated_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Estimated date' AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_boolean, creator, date_created, uuid)
            VALUES (patient_id, @date_of_hiv_pos_test_estimated_concept_id, old_enc_id, encounter_datetime, @location_id , date_of_hiv_pos_test_estimated, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @date_of_hiv_pos_test_estimated_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(location_of_hiv_pos_test) THEN

            # Get concept_id
            SET @location_of_hiv_pos_test_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'CONFIRMATORY HIV TEST LOCATION' AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
            VALUES (patient_id, @location_of_hiv_pos_test_concept_id, old_enc_id, encounter_datetime, @location_id , location_of_hiv_pos_test, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @location_of_hiv_pos_test_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(arv_number_at_that_site) THEN

            # Get concept_id
            SET @arv_number_at_that_site_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'ART number at previous location' AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
            VALUES (patient_id, @arv_number_at_that_site_concept_id, old_enc_id, encounter_datetime, @location_id , arv_number_at_that_site, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @arv_number_at_that_site_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(location_of_art_initiation) THEN

            # Get concept_id
            SET @location_of_art_initiation_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Location of ART initiation' AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
            VALUES (patient_id, @location_of_art_initiation_concept_id, old_enc_id, encounter_datetime, @location_id , location_of_art_initiation, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @location_of_art_initiation_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(taken_arvs_in_last_two_months) THEN

            # Get concept_id
            SET @taken_arvs_in_last_two_months_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Has the patient taken ART in the last two months' AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded id
            SET @taken_arvs_in_last_two_months_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = taken_arvs_in_last_two_months AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded_name_id
            SET @taken_arvs_in_last_two_months_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = taken_arvs_in_last_two_months AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
            VALUES (patient_id, @taken_arvs_in_last_two_months_concept_id, old_enc_id, encounter_datetime, @location_id , @taken_arvs_in_last_two_months_value_coded, @taken_arvs_in_last_two_months_value_coded_name_id, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @taken_arvs_in_last_two_months_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(taken_arvs_in_last_two_weeks) THEN

            # Get concept_id
            SET @taken_arvs_in_last_two_weeks_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Has the patient taken ART in the last two weeks' AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded id
            SET @taken_arvs_in_last_two_weeks_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = taken_arvs_in_last_two_weeks AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded_name_id
            SET @taken_arvs_in_last_two_weeks_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = taken_arvs_in_last_two_weeks AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
            VALUES (patient_id, @taken_arvs_in_last_two_weeks_concept_id, old_enc_id, encounter_datetime, @location_id , @taken_arvs_in_last_two_weeks_value_coded, @taken_arvs_in_last_two_weeks_value_coded_name_id, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @taken_arvs_in_last_two_weeks_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(has_transfer_letter) THEN

            # Get concept_id
            SET @has_transfer_letter_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Has transfer letter' AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded id
            SET @has_transfer_letter_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = has_transfer_letter AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded_name_id
            SET @has_transfer_letter_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = has_transfer_letter AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
            VALUES (patient_id, @has_transfer_letter_concept_id, old_enc_id, encounter_datetime, @location_id , @has_transfer_letter_value_coded, @has_transfer_letter_value_coded_name_id, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @has_transfer_letter_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(site_transferred_from) THEN

            # Get concept_id
            SET @site_transferred_from_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Transfer in from' AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
            VALUES (patient_id, @site_transferred_from_concept_id, old_enc_id, encounter_datetime, @location_id , site_transferred_from, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @site_transferred_from_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(date_of_art_initiation) THEN

            # Get concept_id
            SET @date_of_art_initiation_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Date antiretrovirals started' AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_datetime, creator, date_created, uuid)
            VALUES (patient_id, @date_of_art_initiation_concept_id, old_enc_id, encounter_datetime, @location_id , date_of_art_initiation, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @date_of_art_initiation_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(ever_registered_at_art) THEN

            # Get concept_id
            SET @ever_registered_at_art_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Ever registered at ART clinic' AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded id
            SET @ever_registered_at_art_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = ever_registered_at_art AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded_name_id
            SET @ever_registered_at_art_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = ever_registered_at_art AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
            VALUES (patient_id, @ever_registered_at_art_concept_id, old_enc_id, encounter_datetime, @location_id , @ever_registered_at_art_value_coded, @ever_registered_at_art_value_coded_name_id, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @ever_registered_at_art_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(ever_received_arv) THEN

            # Get concept_id
            SET @ever_received_arv_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Ever received ART' AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded id
            SET @ever_received_arv_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = ever_received_arv AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded_name_id
            SET @ever_received_arv_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = ever_received_arv AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
            VALUES (patient_id, @ever_received_arv_concept_id, old_enc_id, encounter_datetime, @location_id , @ever_received_arv_value_coded, @ever_received_arv_value_coded_name_id, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @ever_received_arv_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(last_arv_regimen) THEN

            # Get concept_id
            SET @last_arv_regimen_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Last ART drugs taken' AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded id
            SET @last_arv_regimen_value_coded = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = last_arv_regimen AND voided = 0 AND retired = 0 LIMIT 1);

            # Get value_coded_name_id
            SET @last_arv_regimen_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = last_arv_regimen AND voided = 0 AND retired = 0 LIMIT 1);
            
            #save as value_text if value_coded is null
            IF ISNULL(@last_arv_regimen_value_coded) THEN
              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_text, creator, date_created, uuid)
              VALUES (patient_id, @last_arv_regimen_concept_id, old_enc_id, encounter_datetime, @location_id , last_arv_regimen, @creator, date_created, (SELECT UUID()));
            ELSE
              # Create observation
              INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_coded, value_coded_name_id, creator, date_created, uuid)
              VALUES (patient_id, @last_arv_regimen_concept_id, old_enc_id, encounter_datetime, @location_id , @last_arv_regimen_value_coded, @last_arv_regimen_value_coded_name_id, @creator, date_created, (SELECT UUID()));
            END IF;

            # Get last obs id for association later to other records
            SET @last_arv_regimen_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(date_last_arv_taken) THEN

            # Get concept_id
            SET @date_last_arv_taken_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Date ART last taken' AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_datetime, creator, date_created, uuid)
            VALUES (patient_id, @date_last_arv_taken_concept_id, old_enc_id, encounter_datetime, @location_id , date_last_arv_taken, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @date_last_arv_taken_id = (SELECT LAST_INSERT_ID());

        END IF;
        
        # Check if the field is not empty
        IF NOT ISNULL(date_last_arv_taken_estimated) THEN

            # Get concept_id
            SET @date_last_arv_taken_estimated_concept_id = (SELECT concept_name.concept_id FROM concept_name concept_name
                        LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id
                        WHERE name = 'Estimated date' AND voided = 0 AND retired = 0 LIMIT 1);

            # Create observation
            INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id , value_boolean, creator, date_created, uuid)
            VALUES (patient_id, @date_last_arv_taken_estimated_concept_id, old_enc_id, encounter_datetime, @location_id , date_last_arv_taken_estimated, @creator, date_created, (SELECT UUID()));

            # Get last obs id for association later to other records
            SET @date_last_arv_taken_estimated_id = (SELECT LAST_INSERT_ID());

        END IF;
        
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
            VALUES (patient_id, @height_concept_id, old_enc_id, encounter_datetime, @location_id , height, @creator, date_created, (SELECT UUID()));
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


	END LOOP;

END$$

DELIMITER ;
