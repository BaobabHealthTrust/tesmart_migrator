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
DROP PROCEDURE IF EXISTS `proc_opd_encounters`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_opd_encounters`(
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

        # Get last person id for association later to other records
        SET @person_id = (patient_id);
        
        select patient_id;
        
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

