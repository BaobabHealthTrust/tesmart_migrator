# This procedure imports outcome encounters from intermediate tables to ART2 OpenMRS database
# I decided to use default values / hardcoded values to reduce database reads

# encounter_type ====> 40
# states : pre-art => 1
# died => 3
# transfered_out => 2
# treatment_stopped => 6
# on_art => 7
#
# mapping explained
    -- On Art => Add a state On_Art
    -- died => update person, set died = true and date_died -- This is a terminal state
    -- transfered out => Update program, set it closed, add state -- This is a terminal state
    -- pre_art => Add state
    -- treatment_stopped => Update state -- This is a terminal state

    # Terminal states
    -- Create an Exit from care encounter (119) with associated observations
# end mapping

# The default DELIMITER is disabled to avoid conflicting with our scripts
DELIMITER $$

# Check if a similar procedure exists and drop it so we can start from a clean slate
DROP PROCEDURE IF EXISTS `proc_import_outcome_encounter`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_import_outcome_encounter`(
IN in_patient_id INT(11)
)
BEGIN
    # Declare condition for exiting loop
    DECLARE done INT DEFAULT FALSE;
    
    # Declare fields to hold our values for our patients
    DECLARE id int(11);
    DECLARE visit_encounter_id int(11);
    DECLARE old_enc_id int(11);
    DECLARE patient_id int(11);
    DECLARE state VARCHAR(255);
    DECLARE outcome_date DATE;
    DECLARE transfer_out_location VARCHAR(255);
    DECLARE location VARCHAR(255);
    DECLARE voided INT(11);
    DECLARE void_reason VARCHAR(255);
    DECLARE date_voided DATE;
    DECLARE voided_by INT(11);
    DECLARE date_created DATETIME;
    DECLARE creator varchar(255);
    
    # Declare and initialise cursor for looping through the table
    DECLARE cur CURSOR FOR SELECT * FROM `bart1_intermediate_bare_bones`.`outcome_encounters`
                           WHERE `bart1_intermediate_bare_bones`.`outcome_encounters`.`patient_id` = in_patient_id;

    # Declare loop position check
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    # Open cursor
    OPEN cur;

    # Declare loop for traversing through the records
    read_loop: LOOP
        # Get the fields into the variables declared earlier
        FETCH cur INTO id, visit_encounter_id, old_enc_id, patient_id, state, outcome_date, transfer_out_location,
                        location, voided, void_reason, date_voided, voided_by, date_created, creator;
    
        # Check if we are done and exit loop if done
        IF done THEN
        
            LEAVE read_loop;
        
        END IF;

        # Map destination user to source user
        SET @creator = COALESCE((SELECT user_id FROM users WHERE username = creator), 1);
        
        # Map destination user to source voided_by
        SET @provider = COALESCE((SELECT person_id FROM users WHERE user_id = @creator), 1);
        
        # Map destination user to source voided_by
        SET @voided_by = (SELECT user_id FROM users WHERE user_id = voided_by LIMIT 1);
        
        # Map location to source location
        SET @location_id = COALESCE((SELECT location_id FROM location WHERE name = location LIMIT 1), 1);
        
        # Map encounter_id to source
        SET @encounter_type_id =(SELECT encounter_type_id
                                            FROM encounter_type
                                            WHERE name = 'UPDATE OUTCOME' LIMIT 1);
        # Get hiv program for the patient
        SET @patient_hiv_program = COALESCE((SELECT patient_program_id
                                                FROM patient_program
                                                WHERE patient_id = patient_program.patient_id), 0);
        
        # Create outcome encounter object in destination

        INSERT INTO encounter (encounter_id, patient_id, provider_id, encounter_type,location_id, encounter_datetime, creator, voided, voided_by, date_voided, void_reason, uuid)
        VALUES (old_enc_id, patient_id, @provider, @encounter_type_id, @location_id, date_created, @creator, voided, @voided_by, date_voided, void_reason,(SELECT UUID())) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

        # Get the latest encounter created
     SET @encounter_id = (SELECT LAST_INSERT_ID());
        
        IF @patient_hiv_program = 0 THEN #no HIV program present
                SET @hiv_program = COALESCE((SELECT program_id FROM program WHERE name = 'HIV PROGRAM'), 1);
                    
                INSERT INTO patient_program(patient_id, program_id, date_enrolled, creator, location_id, uuid)
                VALUES (patient_id, @hiv_program, outcome_date, @creator, @location_id, (SELECT UUID()));

                SET @patient_hiv_program = (SELECT patient_program_id
                                            FROM patient_program
                                            WHERE patient_id = patient_program.patient_id AND program_id = @hiv_program);
        END IF;
         # get the previous state if there is one
        SET @previous_state = COALESCE((SELECT max(patient_state_id)
                                        FROM patient_state
                                        WHERE patient_program_id = @patient_hiv_program AND voided = 0), 0);

        # Create States for the patient
        IF NOT ISNULL(state) THEN
          IF COALESCE(state, "") != "" THEN
              IF state = 'On ART' THEN
                  INSERT INTO patient_state (patient_program_id, state, start_date, creator, voided, voided_by,
                                      date_voided, void_reason, uuid) VALUES (@patient_hiv_program, 7,
                                      date_created, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
              ELSEIF state = 'PRE ART' THEN
                  INSERT INTO patient_state (patient_program_id, state, start_date, creator, voided, voided_by,
                                      date_voided, void_reason, uuid) VALUES (@patient_hiv_program, 1,
                                      date_created, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
              ELSEIF state = 'Transfer Out(With Transfer Note)' THEN
                  SET @terminal_state_encounter_type_id = (SELECT encounter_type_id
                                                              FROM encounter_type WHERE name = 'EXIT FROM HIV CARE');
                  INSERT INTO patient_state (patient_program_id, state, start_date, creator, voided, voided_by,
                                      date_voided, void_reason, uuid) VALUES (@patient_hiv_program, 2,
                                      date_created, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
              ELSEIF state = 'Died' THEN
                  SET @terminal_state_encounter_type_id = (SELECT encounter_type_id
                                                              FROM encounter_type WHERE name = 'EXIT FROM HIV CARE');
                  INSERT INTO patient_state (patient_program_id, state, start_date, creator, voided, voided_by,
                                      date_voided, void_reason, uuid) VALUES (@patient_hiv_program, 3,
                                      date_created, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
              ELSEIF state = 'ART Stop' THEN
                  SET @terminal_state_encounter_type_id = (SELECT encounter_type_id
                                                              FROM encounter_type WHERE name = 'EXIT FROM HIV CARE');
                  INSERT INTO patient_state (patient_program_id, state, start_date, creator, voided, voided_by,
                                      date_voided, void_reason, uuid) VALUES (@patient_hiv_program, 6,
                                      date_created, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
              ELSEIF state = 'Transfer Out(Without Transfer Note)' THEN
                  SET @terminal_state_encounter_type_id = (SELECT encounter_type_id
                                                              FROM encounter_type WHERE name = 'EXIT FROM HIV CARE');
                  INSERT INTO patient_state (patient_program_id, state, start_date, creator, voided, voided_by,
                                      date_voided, void_reason, uuid) VALUES (@patient_hiv_program, 2,
                                      date_created, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
              END IF;
          END IF; # end of state
        
        #close the previous state
        IF @previous_state != 0 THEN # previous state exists, therefore update the end date
            IF voided != 1 THEN #if the currently inserted state is not voided, then close the previous state
                UPDATE patient_state SET end_date = date_created WHERE patient_state_id = @previous_state;
            END IF;
        END IF; # end of previous state

        # Create workstation location Observation for the encounter
            -- INSERT INTO obs (person_id,concept_id,encounter_id, obs_datetime,location_id, value_coded, value_coded_name_id,creator, voided, voided_by, date_voided, void_reason, uuid)
            -- VALUES (patient_id, 1805, @encounter_id, date_created, 1, 1065, 1102, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
        
        # Create Transfered out Location

        -- IF COALESCE(transfer_out_location, "") != "" THEN
            -- INSERT INTO obs (person_id,concept_id,encounter_id, obs_datetime,location_id, value_coded, value_coded_name_id,creator, voided, voided_by, date_voided, void_reason, uuid)
            -- VALUES (patient_id, 1805, @encounter_id, date_created, 1, 1065, 1102, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
        -- END IF; # end of transfer out location
        
        # Work on Terminal states
        # Create exit from care encounter
        IF (state = 'Died' OR state = 'ART Stop' OR state = 'Transfer Out(With Transfer Note)'
            OR state = 'Transfer Out(Without Transfer Note)') THEN
    
            INSERT INTO encounter (patient_id, provider_id, encounter_type,location_id, encounter_datetime, creator, voided, voided_by, date_voided, void_reason, uuid)
            VALUES (patient_id,@provider, @terminal_state_encounter_type_id, @location_id, date_created, @creator,
                            voided, @voided_by, date_voided, void_reason,(SELECT UUID())) ON DUPLICATE KEY UPDATE encounter_id = old_enc_id;

            SET @new_encounter_id = (SELECT LAST_INSERT_ID());
            SET @date_of_exiting_care_concept = (SELECT concept_id FROM concept_name WHERE name = 'Date of exiting care');
            #insert Date of exiting from care observation
            INSERT INTO obs (person_id,concept_id, encounter_id, obs_datetime,location_id, value_datetime, creator, voided, voided_by, date_voided, void_reason, uuid)
            VALUES (patient_id, @date_of_exiting_care_concept, @new_encounter_id, outcome_date, @location_id,
                            outcome_date, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
            
            SET @reason_concept = (SELECT concept_id FROM concept_name WHERE name = 'Reason for exiting care');

            IF state = 'Died' THEN
                #update person table with status died
                IF voided != 1 THEN
                    UPDATE person
                        SET dead = 1, death_date = outcome_date,
                        changed_by = @creator, date_changed = outcome_date
                    WHERE person_id = patient_id;
                END IF;

                SET @reason_value_coded = (SELECT concept_id FROM concept_name WHERE name = 'Patient died');
                SET @reason_value_coded_name_id = (SELECT concept_name_id FROM concept_name WHERE name = 'Patient died');
            ELSEIF state = 'ART Stop' THEN
                SET @reason_value_coded = (SELECT concept_id FROM concept_name WHERE name = 'Treatment stopped');
                SET @reason_value_coded_name_id = (SELECT concept_name_id FROM concept_name WHERE name = 'Treatment stopped');
            ELSEIF state = 'Transfer Out(With Transfer Note)' THEN
                SET @reason_value_coded = (SELECT concept_id FROM concept_name WHERE name = 'Patient transferred out');
                SET @reason_value_coded_name_id = (SELECT concept_name_id FROM concept_name WHERE name = 'Patient transferred out');
            END IF;
            #insert reason for exiting care observation
            INSERT INTO obs (person_id,concept_id,encounter_id, obs_datetime,location_id, value_coded,
                            value_coded_name_id, creator, voided, voided_by, date_voided, void_reason, uuid)
            VALUES (patient_id, @reason_concept, @new_encounter_id, outcome_date, @location_id, @reason_value_coded,
                    @reason_value_coded_name_id, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
            
            #close patient program
            IF voided != 1 THEN
                UPDATE patient_program SET date_completed = date_created WHERE patient_program_id = @patient_hiv_program;
            END IF;
        END IF; # end of terminal status
        
        IF COALESCE(transfer_out_location, "") != "" THEN
            SET @transfer_out_concept = (SELECT concept_name_id FROM concept_name WHERE name = 'Transfer out destination');
            SET @transfer_out_location_id = (SELECT location_id FROM location WHERE name = transfer_out_location);
            
            INSERT INTO obs (person_id,concept_id,encounter_id, obs_datetime,location_id, value_numeric, creator, voided,
                                voided_by, date_voided, void_reason, uuid)
            VALUES (patient_id, @transfer_out_concept, @new_encounter_id, date_created, @location_id,
                @transfer_out_location_id, @creator, voided, @voided_by, date_voided, void_reason, (SELECT UUID()));
        END IF;
     END IF;

 
    END LOOP;

END$$

DELIMITER ;
