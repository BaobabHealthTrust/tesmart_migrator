# This procedure imports patients from intermediate tables to ART2 OpenMRS database
# ASSUMPTION
# ==========
# The assumption here is your source database name is `bart1_intermediate_bare_bones`
# and the destination any name you prefer.
# This has been necessary because there seems to be no way to use dynamic database 
# names in procedures yet

# The default DELIMITER is disabled to avoid conflicting with our scripts
DELIMITER $$

# Check if a similar procedure exists and drop it so we can start from a clean slate
DROP PROCEDURE IF EXISTS `proc_import_patients`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_import_patients`(
  #--IN start_pos INT(11),
  #--IN end_pos INT(11)
  #--IN in_patient_id INT(11)
	)
BEGIN
    
    # Declare condition for exiting loop
    DECLARE done INT DEFAULT FALSE;
    
    # Declare fields to hold our values for our patients
    DECLARE patient_id INT(11);
    DECLARE given_name VARCHAR(255);
    DECLARE middle_name VARCHAR(255);
    DECLARE family_name VARCHAR(255);
    DECLARE gender VARCHAR(25);
    DECLARE dob DATE;
    DECLARE dob_estimated BIT(1);
    DECLARE dead BIT(1);
    DECLARE traditional_authority VARCHAR(255);
    DECLARE current_address VARCHAR(255);
    DECLARE landmark VARCHAR(255);
    DECLARE cellphone_number VARCHAR(255);
    DECLARE home_phone_number VARCHAR(255);
    DECLARE office_phone_number VARCHAR(255);
    DECLARE occupation VARCHAR(255);
    DECLARE guardian_id INT(11);
    DECLARE nat_id VARCHAR(255);
    DECLARE art_number VARCHAR(255);
    DECLARE pre_art_number VARCHAR(255);
    DECLARE tb_number VARCHAR(255);
    DECLARE legacy_id VARCHAR(255);
    DECLARE legacy_id2 VARCHAR(255);
    DECLARE legacy_id3 VARCHAR(255);
    DECLARE new_nat_id VARCHAR(255);
    DECLARE prev_art_number VARCHAR(255);
    DECLARE filing_number VARCHAR(255);
    DECLARE archived_filing_number VARCHAR(255);
    DECLARE voided TINYINT(1);
    DECLARE void_reason VARCHAR(255);
    DECLARE date_voided DATE;
    DECLARE voided_by INT(11);
    DECLARE date_created DATE;
    DECLARE creator varchar(255);

    # Declare and initialise cursor for looping through the table
    DECLARE cur CURSOR FOR SELECT * FROM `bart1_intermediate_bare_bones`.`patients`;
           #--WHERE `bart1_intermediate_bare_bones`.`patients`.`patient_id` BETWEEN start_pos AND end_pos; 
           #--LIMIT start_pos, end_pos;

    # Declare loop position check
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    # Disable system checks and indexing to speed up processing
    SET FOREIGN_KEY_CHECKS = 0;
    SET UNIQUE_CHECKS = 0;
    SET AUTOCOMMIT = 0;

    # Open cursor
    OPEN cur;
    
    # Declare loop for traversing through the records
    read_loop: LOOP
    
        # Get the fields into the variables declared earlier
        FETCH cur INTO patient_id, given_name, middle_name, family_name, gender, dob, dob_estimated, dead, traditional_authority, current_address, landmark, cellphone_number, home_phone_number, office_phone_number, occupation, guardian_id, nat_id, art_number, pre_art_number, tb_number, legacy_id, legacy_id2, legacy_id3, new_nat_id, prev_art_number, filing_number, archived_filing_number, voided, void_reason, date_voided, voided_by, date_created, creator;
    
        # Check if we are done and exit loop if done
        IF done THEN
        
            LEAVE read_loop;
        
        END IF;
    
        # Not done, process the parameters
        
        # Map destination user to source user
        SET @creator = COALESCE((SELECT user_id FROM users WHERE username = creator), 1);
        IF ISNULL(dob_estimated) THEN
          SET @date_of_birth_estimated = (false);
        ELSE
          SET @date_of_birth_estimated = (dob_estimated);
        END IF;

        IF ISNULL(dead) THEN
          SET @patient_dead = (0);
        ELSE
          SET @patient_dead = (dead);
        END IF;

        # Create person object in destination
        INSERT INTO person (person_id, gender, birthdate, birthdate_estimated, dead, creator, date_created, uuid)
        VALUES (patient_id,SUBSTRING(gender, 1, 1), dob, @date_of_birth_estimated, @patient_dead, @creator, date_created, (SELECT UUID()))  ON DUPLICATE KEY UPDATE person_id = patient_id;
    
        # Get last person id for association later to other records
        SET @person_id = (patient_id);
    
        # Create person name details
        INSERT INTO person_name (person_id, given_name, middle_name, family_name, creator, date_created, uuid)
        VALUES (patient_id, given_name, middle_name, family_name, @creator, date_created, (SELECT UUID()));
        
        SET @person_name_id = (SELECT LAST_INSERT_ID());
        
        #create person_name_coded
        INSERT INTO person_name_code (person_name_id, given_name_code, middle_name_code, family_name_code)
        VALUES (@person_name_id, soundex(given_name), soundex(middle_name), soundex(family_name));

        # Check variables for several person attribute type ids
        SET @cellphone_number_type_id = (SELECT person_attribute_type_id FROM person_attribute_type WHERE name = "Cell Phone Number");
        SET @home_phone_number_type_id = (SELECT person_attribute_type_id FROM person_attribute_type WHERE name = "Home Phone Number");
        SET @office_phone_number_type_id = (SELECT person_attribute_type_id FROM person_attribute_type WHERE name = "Office Phone Number");
        SET @occupation_type_id = (SELECT person_attribute_type_id FROM person_attribute_type WHERE name = "Occupation");
        SET @traditional_authority_type_id = (SELECT person_attribute_type_id FROM person_attribute_type WHERE name = "Ancestral Traditional Authority");
        SET @current_address_type_id = (SELECT person_attribute_type_id FROM person_attribute_type WHERE name = "Current Place Of Residence");
        SET @landmark_type_id = (SELECT person_attribute_type_id FROM person_attribute_type WHERE name = "Landmark Or Plot Number");
    
        # Create associated person attributes
        IF COALESCE(traditional_authority, "") != "" THEN
        
            INSERT INTO person_attribute (person_id, value, person_attribute_type_id, creator, date_created, uuid)
            VALUES (patient_id, traditional_authority, @traditional_authority_type_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
    
        IF COALESCE(current_address, "") != "" THEN
            SET @person_address_uuid = (SELECT UUID());

            INSERT INTO person_attribute (person_id, value, person_attribute_type_id, creator, date_created, uuid)
            VALUES (patient_id, current_address, @current_address_type_id, @creator, date_created, (SELECT UUID()));
            
            INSERT INTO person_address (person_id, city_village, creator, date_created, uuid)
            VALUES (patient_id, current_address, @creator, date_created, @person_address_uuid);

            SET @person_address_id = (SELECT person_address_id FROM person_address WHERE uuid = @person_address_uuid);

          IF COALESCE(landmark, "") != "" THEN

            INSERT INTO person_attribute (person_id, value, person_attribute_type_id, creator, date_created, uuid)
            VALUES (patient_id, landmark, @landmark_type_id, @creator, date_created, @person_address_uuid);

            UPDATE person_address SET address1 = landmark
            WHERE uuid = @person_address_uuid;

          END IF;

        END IF;
    
        IF COALESCE(occupation, "") != "" THEN
        
            INSERT INTO person_attribute (person_id, value, person_attribute_type_id, creator, date_created, uuid)
            VALUES (patient_id, occupation, @occupation_type_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
    
        IF COALESCE(office_phone_number, "") != "" THEN
        
            INSERT INTO person_attribute (person_id, value, person_attribute_type_id, creator, date_created, uuid)
            VALUES (patient_id, office_phone_number, @office_phone_number_type_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
    
        IF COALESCE(cellphone_number, "") != "" THEN
        
            INSERT INTO person_attribute (person_id, value, person_attribute_type_id, creator, date_created, uuid)
            VALUES (patient_id, cellphone_number, @cellphone_number_type_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
    
        IF COALESCE(home_phone_number, "") != "" THEN
        
            INSERT INTO person_attribute (person_id, value, person_attribute_type_id, creator, date_created, uuid)
            VALUES (patient_id, home_phone_number, @home_phone_number_type_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
  #--  
        # Create a patient
        INSERT INTO patient (patient_id, creator, date_created)
        VALUES (patient_id, @creator, date_created)  ON DUPLICATE KEY UPDATE patient_id = patient_id;
    
        # Set patient identifier types
        SET @art_number = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = "ARV Number");
        SET @tb_number = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = "District TB Number");
        SET @legacy_id = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = "Old Identification Number");
        SET @new_nat_id = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = "National id");
        SET @nat_id = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = "National id");
        SET @archived_filing_number_id = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = "Archived filing number");
        SET @filing_number_id = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = "Filing number");
        SET @pre_art_number_id = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = "Pre-ART number");
        SET @prev_art_number_id = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = "z_deprecated Pre ART Number (Old format)");
    
        # Location id defaulted to "Unknown" since the source database version 
        # did not capture this field
        SET @location_id = (SELECT location_id FROM location WHERE name = "Unknown");
    
        # Create patient identifiers            
        IF NOT ISNULL(prev_art_number) AND NOT ISNULL(@pre_art_number_id) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, prev_art_number, @prev_art_number_id, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
                                         
        IF NOT ISNULL(pre_art_number) AND NOT ISNULL(@pre_art_number_id) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, pre_art_number, @pre_art_number_id, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
                                  
        IF NOT ISNULL(filing_number) AND NOT ISNULL(@filing_number_id) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, filing_number, @filing_number_id, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
                          
        IF NOT ISNULL(archived_filing_number) AND NOT ISNULL(@archived_filing_number_id) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, archived_filing_number, @archived_filing_number_id, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
                  
        IF NOT ISNULL(nat_id) AND NOT ISNULL(@nat_id) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, nat_id, (CASE WHEN ISNULL(new_nat_id) THEN @nat_id ELSE @legacy_id END), @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
          
        IF NOT ISNULL(new_nat_id) AND NOT ISNULL(@new_nat_id) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, new_nat_id, @new_nat_id, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
    
        IF NOT ISNULL(art_number) AND NOT ISNULL(@art_number) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, art_number, @art_number, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
    
        IF NOT ISNULL(tb_number) AND NOT ISNULL(@tb_number) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, tb_number, @tb_number, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
    
        IF NOT ISNULL(legacy_id) AND NOT ISNULL(@legacy_id) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, legacy_id, @legacy_id, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
    
        IF NOT ISNULL(legacy_id2) AND NOT ISNULL(@legacy_id) THEN

            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, legacy_id2, @legacy_id, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
    
        IF NOT ISNULL(legacy_id3) AND NOT ISNULL(@legacy_id) THEN
        
            INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
            VALUES (patient_id, legacy_id3, @legacy_id, @location_id, @creator, date_created, (SELECT UUID()));
        
        END IF;
        select patient_id;
        select "first_visit_encounter";
        CALL proc_import_first_visit_encounters(@person_id);          # good
        
        select "hiv_reception_encounter";
        CALL proc_import_hiv_reception_encounters(@person_id);        # good
        
        select "vitals_encounter";
        CALL proc_import_vitals_encounters(@person_id);               # good
        
        select "art_visit_encounter";
        CALL proc_import_art_visit_encounters(@person_id);            # good
        
        select "pre_art_visit_encounter";
        CALL proc_import_pre_art_visit_encounters(@person_id);        # good
        
        select "hiv_staging_encounter";        
        CALL proc_import_hiv_staging_encounters(@person_id);          # good

        select "give_drugs_encounter";        
        CALL proc_import_give_drugs(@person_id);                      # good
        
        select "patient_outcome_encounter";        
        CALL proc_import_patient_outcome(@person_id);                 # good
        
        select "guardians_encounter";        
        CALL proc_import_guardians(@person_id);                       # good
        
        select "general_reception_encounter";        
        CALL proc_import_general_reception_encounters(@person_id);    # good
        
        select "outpatient_diagnosis_encounter";        
        CALL proc_import_outpatient_diagnosis_encounters(@person_id); # good

        select patient_id;

    END LOOP;

    SET UNIQUE_CHECKS = 1;
    SET FOREIGN_KEY_CHECKS = 1;
    COMMIT;
    SET AUTOCOMMIT = 1;

END$$

DELIMITER ;

