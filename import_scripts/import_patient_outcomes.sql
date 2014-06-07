# This procedure imports outcome encounters from intermediate tables to ART2 OpenMRS database
# I decided to use default values / hardcoded values to reduce database reads

# encounter_type ====> 40
# states :  pre-art             =>  1
#           died                =>  3
#           transfered_out      =>  2
#           treatment_stopped   =>  6
#           on_art              =>  7
#
#  mapping explained    
    -- On Art   => Add a state On_Art 
    -- died     => update person, set died = true and date_died -- This is a terminal state
    -- transfered out   => Update program, set it closed, add state -- This is a terminal state
    -- pre_art  => Add state 
    -- treatment_stopped => Update state -- This is a terminal state

    # Terminal states
    -- Create an Exit from care encounter (119) with associated observations 
#  end mapping

# The default DELIMITER is disabled to avoid conflicting with our scripts
DELIMITER $$

# Check if a similar procedure exists and drop it so we can start from a clean slate
DROP PROCEDURE IF EXISTS `proc_import_patient_outcome`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_import_patient_outcome`(
	IN in_patient_id INT(11)
)
BEGIN
    # Declare condition for exiting loop
    DECLARE done INT DEFAULT FALSE;
    
    # Declare fields to hold our values for our patients
    DECLARE id int(11);
    DECLARE visit_encounter_id int(11);
    DECLARE outcome_id int(11);
    DECLARE patient_id int(11);
    DECLARE outcome_state VARCHAR(255);
    DECLARE outcome_date DATE; 
    
    # Declare and initialise cursor for looping through the table
    DECLARE cur CURSOR FOR SELECT * FROM `bart1_intermediate_bare_bones`.`patient_outcomes`
                           WHERE `bart1_intermediate_bare_bones`.`patient_outcomes`.`patient_id` = in_patient_id;

    # Declare loop position check
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    # Open cursor
    OPEN cur;

    # Declare loop for traversing through the records
    read_loop: LOOP
        # Get the fields into the variables declared earlier
        FETCH cur INTO id, visit_encounter_id, outcome_id, patient_id, outcome_state, outcome_date;
    
        # Check if we are done and exit loop if done
        IF done THEN
        
            LEAVE read_loop;
        
        END IF;

    IF NOT ISNULL(patient_id) THEN
      # create exit_from_hiv_care encounter
      SET @terminal_state_encounter_type_id = (SELECT encounter_type_id 
                                                       FROM encounter_type 
                                                       WHERE name = 'EXIT FROM HIV CARE');
          
      #get date_of_exiting_care_concept_id
      SET @date_of_exiting_care_concept = (SELECT concept_name.concept_id FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                WHERE name = 'Date of exiting care' AND voided = 0 AND retired = 0 LIMIT 1);
          
      #get reason_for_exiting_care_concept_id
      SET @reason_for_existing_care_concept_id = (SELECT concept_name.concept_id FROM concept_name
                                LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                WHERE name = 'Reason for exiting care' AND voided = 0 AND retired = 0 LIMIT 1);
      
      #check if the patient is already enrolled in HIV Program
      SET @patient_hiv_program_id = COALESCE((SELECT patient_program_id 
                                                    FROM patient_program pp
                                                    WHERE pp.patient_id = patient_id), 0);
    
      #check if the patient is already enrolled in HIV Program
      SET @patient_hiv_program_id = COALESCE((SELECT patient_program_id 
                                                    FROM patient_program pp
                                                    WHERE pp.patient_id = patient_id), 0);
      #check if patient has patient_program
      IF (@patient_hiv_program_id = 0) THEN
        # create patient_program
          SET @hiv_program = COALESCE((SELECT program_id FROM program WHERE name = 'HIV PROGRAM'), 1);
                        
          INSERT INTO patient_program(patient_id, program_id, date_enrolled, creator, uuid)
          VALUES (patient_id, @hiv_program, outcome_date, 1, (SELECT UUID()));

          SET @patient_hiv_program_id = (SELECT patient_program_id 
                                         FROM patient_program pp 
                                         WHERE patient_id = pp.patient_id AND program_id = @hiv_program);

          # create the new state
          IF NOT ISNULL(outcome_state) THEN
            IF outcome_state = 'On ART' THEN
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid)
              VALUES (@patient_hiv_program_id, 7, outcome_date, 1 , outcome_date,(SELECT UUID()));
            
            ELSEIF outcome_state = 'Pre-ART' THEN
              INSERT INTO patient_state (patient_program_id, state, start_date, creator,  date_created, uuid) 
              VALUES (@patient_hiv_program_id, 1, outcome_date, 1 , outcome_date,(SELECT UUID()));
            
            ELSEIF outcome_state = 'ART Stop' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
                        VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id,outcome_date,outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Treatment stopped' AND voided = 0 AND retired = 0 LIMIT 1);

              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Treatment stopped' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
               
              #create state                                                       
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created, uuid) 
              VALUES (@patient_hiv_program_id, 6, outcome_date, 1 , outcome_date,(SELECT UUID()));

            ELSEIF outcome_state = 'Died' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
                        VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient died' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient died' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));

              #update person table with status died
              UPDATE person SET dead = 1, death_date = outcome_date, date_changed = outcome_date 
              WHERE person_id = patient_id;
                                                       
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 3, outcome_date, 1 , outcome_date, (SELECT UUID()));
            
            ELSEIF outcome_state = 'Transfer out' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
              VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
              
              #create patient_state                                        
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 2, outcome_date, 1 , outcome_date,(SELECT UUID()));
            
            ELSEIF outcome_state = 'Transfer Out(With Transfer Note)' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
              VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
              
              #create patient_state                                        
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 2, outcome_date, 1 , outcome_date,(SELECT UUID()));
            
            ELSEIF outcome_state = 'Transfer Out(Without Transfer Note)' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
              VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
              
              #create patient_state                                        
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 2, outcome_date, 1 , outcome_date,(SELECT UUID()));

            ELSEIF outcome_state = 'Missing' THEN
              # create update_outcome encounter and outcome observation
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 1, outcome_date, 1 , outcome_date,(SELECT UUID()));
              
            ELSEIF outcome_state = 'Never Started ART' THEN
              # create update_outcome encounter and outcome observation
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 1, outcome_date, 1 , outcome_date,(SELECT UUID()));

            #--ELSE
            #--  select patient_id;
            END IF;
             #-- select patient_id, state;
          #--ELSE
           #-- select patient_id;
          END IF; #end_state

      ELSE #patient_program
        # check if patient have a previous state
        SET @previous_state = COALESCE((SELECT max(patient_state_id) 
                                        FROM patient_state 
                                        WHERE patient_program_id = @patient_hiv_program_id AND voided = 0), 0);
                                                                                
        IF (@previous_state = 0) THEN
          # create the new state
          IF NOT ISNULL(outcome_state) THEN
            IF outcome_state = 'On ART' THEN

		            INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid)
		            VALUES (@patient_hiv_program_id, 7, outcome_date, 1 , outcome_date,(SELECT UUID()));
            ELSEIF outcome_state = 'Pre-ART' THEN
              INSERT INTO patient_state (patient_program_id, state, start_date, creator,  date_created, uuid) 
              VALUES (@patient_hiv_program_id, 1, outcome_date, 1 , outcome_date,(SELECT UUID()));
            
            ELSEIF outcome_state = 'ART Stop' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
                        VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id,outcome_date,outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Treatment stopped' AND voided = 0 AND retired = 0 LIMIT 1);

              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Treatment stopped' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
               
              #create state                                                       
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created, uuid) 
              VALUES (@patient_hiv_program_id, 6, outcome_date, 1 , outcome_date,(SELECT UUID()));

            ELSEIF outcome_state = 'Died' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
                        VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient died' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient died' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));

              #update person table with status died
              UPDATE person SET dead = 1, death_date = outcome_date, date_changed = outcome_date 
              WHERE person_id = patient_id;
                                                       
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 3, outcome_date, 1 , outcome_date, (SELECT UUID()));
            
            ELSEIF outcome_state = 'Transfer out' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
              VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
              
              #create patient_state                                        
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 2, outcome_date, 1 , outcome_date,(SELECT UUID()));
            
            ELSEIF outcome_state = 'Transfer Out(With Transfer Note)' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
              VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
              
              #create patient_state                                        
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 2, outcome_date, 1 , outcome_date,(SELECT UUID()));
            
            ELSEIF outcome_state = 'Transfer Out(Without Transfer Note)' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
              VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
              
              #create patient_state                                        
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 2, outcome_date, 1 , outcome_date,(SELECT UUID()));

            ELSEIF outcome_state = 'Missing' THEN
              # create update_outcome encounter and outcome observation
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 1, outcome_date, 1 , outcome_date,(SELECT UUID()));
              
            ELSEIF outcome_state = 'Never Started ART' THEN
              # create update_outcome encounter and outcome observation
              INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
              VALUES (@patient_hiv_program_id, 1, outcome_date, 1 , outcome_date,(SELECT UUID()));

            #--ELSE
            #--  select patient_id;
            END IF;
            #--  select patient_id, state;
          #--ELSE
           #-- select patient_id;
          END IF; #end_state

        ELSE #previous_state

	        SET @last_state = (SELECT state FROM patient_state 
        										WHERE patient_state_id = @previous_state);                                

          # close the previous state
          #--IF @previous_state != 0  THEN # previous state exists, therefore update the end date
          #--  #check if previous_state is voided 
          #--  UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state and voided = 0;
          #--END IF; # end of previous state

          # create the new state
          IF NOT ISNULL(outcome_state) THEN
            IF outcome_state = 'On ART' THEN
            	IF @last_state != 7 THEN	
		            INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid)
		            VALUES (@patient_hiv_program_id, 7, outcome_date, 1 , outcome_date,(SELECT UUID()));
		          #--ELSE 
		          	UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state;
            	END IF;            
            ELSEIF outcome_state = 'Pre-ART' THEN
            	IF @last_state != 1 THEN	
		            INSERT INTO patient_state (patient_program_id, state, start_date, creator,  date_created, uuid) 
		            VALUES (@patient_hiv_program_id, 1, outcome_date, 1 , outcome_date,(SELECT UUID()));
            	#--ELSE
		          	UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state;
            	END IF;
            ELSEIF outcome_state = 'ART Stop' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
                        VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id,outcome_date,outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Treatment stopped' AND voided = 0 AND retired = 0 LIMIT 1);

              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Treatment stopped' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
               
              #create state                     
             	IF @last_state != 6 THEN	                                  
		            INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created, uuid) 
		            VALUES (@patient_hiv_program_id, 6, outcome_date, 1 , outcome_date,(SELECT UUID()));
							#--ELSE
		          	UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state;							
							END IF;
            ELSEIF outcome_state = 'Died' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
                        VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient died' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient died' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));

              #update person table with status died
              UPDATE person SET dead = 1, death_date = outcome_date, date_changed = outcome_date 
              WHERE person_id = patient_id;
                                                       
             	IF @last_state != 3 THEN	                                                                
		            INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
		            VALUES (@patient_hiv_program_id, 3, outcome_date, 1 , outcome_date, (SELECT UUID()));
            	#--ELSE
		          	UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state;           	
            	END IF;
            ELSEIF outcome_state = 'Transfer out' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
              VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
              
              #create patient_state                                        
             	IF @last_state != 2 THEN	                                                              
		            INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
		            VALUES (@patient_hiv_program_id, 2, outcome_date, 1 , outcome_date,(SELECT UUID()));
							#--ELSE
		          	UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state;   							
							END IF;
							            
            ELSEIF outcome_state = 'Transfer Out(With Transfer Note)' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
              VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
              
              #create patient_state                                        
							IF @last_state != 2 THEN
		            INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
		            VALUES (@patient_hiv_program_id, 2, outcome_date, 1 , outcome_date,(SELECT UUID()));
							#--ELSE
								UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state;   							
							END IF;
            
            ELSEIF outcome_state = 'Transfer Out(Without Transfer Note)' THEN
              #create exit_from_care_encounter
              INSERT INTO temp_encounter (patient_id, provider_id, encounter_type, encounter_datetime, creator, uuid)
              VALUES (patient_id, 1, @terminal_state_encounter_type_id, outcome_date, 1, (SELECT UUID()));

              SET @new_encounter_id = (SELECT LAST_INSERT_ID());

              #insert Date of exiting from care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_datetime, creator,uuid)
              VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, outcome_date, 1,(SELECT UUID()));

              SET @reason_value_coded = (SELECT concept_name.concept_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);
                                              
              SET @reason_value_coded_name_id = (SELECT concept_name.concept_name_id FROM concept_name
                                              LEFT OUTER JOIN concept ON concept.concept_id = concept_name.concept_id 
                                              WHERE name = 'Patient transferred out' AND voided = 0 AND retired = 0 LIMIT 1);

              #insert reason for exiting care observation
              INSERT INTO temp_obs (person_id, concept_id, encounter_id, obs_datetime, value_coded, value_coded_name_id, creator, uuid)
              VALUES (patient_id, @reason_for_existing_care_concept_id, @new_encounter_id, outcome_date, @reason_value_coded, @reason_value_coded_name_id, 1,(SELECT UUID()));
              
              #create patient_state                                  
              IF @last_state != 2 THEN      
		            INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
		            VALUES (@patient_hiv_program_id, 2, outcome_date, 1 , outcome_date,(SELECT UUID()));
							#--ELSE
								UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state; 						
							END IF;

            ELSEIF outcome_state = 'Missing' THEN
              # create update_outcome encounter and outcome observation                            
              IF @last_state != 1 THEN      
		            INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
		            VALUES (@patient_hiv_program_id, 1, outcome_date, 1 , outcome_date,(SELECT UUID()));
              #--ELSE
								UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state; 						
              END IF;
              
            ELSEIF outcome_state = 'Never Started ART' THEN
              # create update_outcome encounter and outcome observation
              IF @last_state != 1 THEN                    
		            INSERT INTO patient_state (patient_program_id, state, start_date, creator, date_created,uuid) 
		            VALUES (@patient_hiv_program_id, 1, outcome_date, 1 , outcome_date,(SELECT UUID()));
							#--ELSE
								UPDATE patient_state SET end_date = outcome_date WHERE patient_state_id = @previous_state; 						
							END IF;

            #--ELSE
            #--  select patient_id;
            END IF;
              #--select patient_id, state;
          #--ELSE
          #--  select patient_id;
          END IF; #end_state
        END IF; #end previous_state

        #--IF COALESCE(transfer_out_location, "") != "" THEN
        #--        SET @transfer_out_concept = (SELECT concept_name_id FROM concept_name WHERE name = 'Transfer out destination');
        #--        SET @transfer_out_location_id = (SELECT location_id FROM location WHERE name = transfer_out_location);
        #--        
        #--        INSERT INTO obs (person_id,concept_id,encounter_id, obs_datetime,location_id, value_numeric, creator, voided, 
        #--                            voided_by, date_voided, void_reason, uuid)
        #--       VALUES (patient_id, @transfer_out_concept, @new_encounter_id, date_created, @location_id, 
        #--            @transfer_out_location_id, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
        #--    END IF;
        #-- END IF;
      END IF; #end_patient_program
    END IF; #end_patient
  END LOOP;

END$$

DELIMITER ;
