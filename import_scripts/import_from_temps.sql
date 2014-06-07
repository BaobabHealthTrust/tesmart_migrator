DELIMITER $$
# Check if a similar procedure exists and drop it so we can start from a clean slate
DROP PROCEDURE IF EXISTS `proc_import_from_temp`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_import_from_temp`()

BEGIN

     # Declare condition for exiting loop
    DECLARE done INT DEFAULT FALSE;

    DECLARE var_id int(11);
    DECLARE var_encounter_type int(11) ;
    DECLARE var_patient_id int(11)   ;
    DECLARE var_provider_id int(11)  ;
    DECLARE var_location_id int(11)  ;
    DECLARE var_form_id int(11)  ;
    DECLARE var_encounter_datetime datetime  ;
    DECLARE var_creator int(11)   ;
    DECLARE var_date_created datetime   ;
    DECLARE var_voided smallint(6)   ;
    DECLARE var_voided_by int(11)  ;
    DECLARE var_date_voided datetime ;
    DECLARE var_void_reason varchar(255) ;
    DECLARE var_uuid char(38) ;
    DECLARE var_changed_by int(11) ;
    DECLARE var_date_changed datetime ;


    DECLARE cur CURSOR FOR SELECT * FROM temp_encounter;

    # Declare loop position check
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
     # Open cursor
    OPEN cur;

    # Declare loop for traversing through the records
    read_loop: LOOP

    FETCH cur INTO

        var_id,
        var_encounter_type,
        var_patient_id,
        var_provider_id,
        var_location_id,
        var_form_id,
        var_encounter_datetime,
        var_creator,
        var_date_created,
        var_voided,
        var_voided_by,
        var_date_voided,
        var_void_reason,
        var_uuid,
        var_changed_by,
        var_date_changed;

    # Check if we are done and exit loop if done
    IF done THEN

      LEAVE read_loop;

    END IF;

      SET @provider_id = COALESCE((SELECT person_id FROM users WHERE user_id = var_provider_id), 1);
      
      INSERT INTO encounter (encounter_type, patient_id, provider_id, encounter_datetime, creator, date_created, uuid)
      VALUES (var_encounter_type, var_patient_id, @provider_id, var_encounter_datetime, var_creator, var_date_created, var_uuid);
      select var_patient_id, var_encounter_type;
      CALL proc_import_obs_from_temp(var_id, last_insert_id());

    END LOOP;

END$$

DELIMITER ;

