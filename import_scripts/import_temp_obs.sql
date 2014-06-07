DELIMITER $$
# Check if a similar procedure exists and drop it so we can start from a clean slate
DROP PROCEDURE IF EXISTS `proc_import_obs_from_temp`$$

# Procedure does not take any parameters. It assumes fixed table names and database
# names as working with flexible names is not supported as of writing in MySQL.
CREATE PROCEDURE `proc_import_obs_from_temp`(IN temp_enc_id INT(11), IN new_enc_id INT(11))

BEGIN

     # Declare condition for exiting loop
    DECLARE done INT DEFAULT FALSE;

   	DECLARE var_obs_id int(11);
	DECLARE var_person_id int(11);
	DECLARE var_concept_id int(11);
	DECLARE var_encounter_id int(11);
	DECLARE var_order_id int(11);
  DECLARE var_obs_datetime datetime;
	DECLARE var_location_id int(11);
	DECLARE var_obs_group_id int(11);
	DECLARE var_accession_number varchar(255);
	DECLARE var_value_group_id int(11);
	DECLARE var_value_boolean tinyint(1);
	DECLARE var_value_coded int(11);
	DECLARE var_value_coded_name_id int(11);
	DECLARE var_value_drug int(11);
	DECLARE var_value_datetime datetime;
	DECLARE var_value_numeric double;
	DECLARE var_value_modifier varchar(2);
	DECLARE var_value_text text;
	DECLARE var_date_started datetime;
	DECLARE var_date_stopped datetime;
	DECLARE var_comments varchar(255);
	DECLARE var_creator int(11);
	DECLARE var_date_created datetime;
	DECLARE var_voided smallint(6);
	DECLARE var_voided_by int(11);
	DECLARE var_date_voided datetime;
	DECLARE var_void_reason varchar(255);
	DECLARE var_value_complex varchar(255);
	DECLARE var_uuid char(38);


    DECLARE cur CURSOR FOR SELECT * FROM temp_obs WHERE encounter_id = temp_enc_id;

    # Declare loop position check
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

     # Open cursor
    OPEN cur;

    # Declare loop for traversing through the records
    read_loop: LOOP

    FETCH cur INTO
       var_obs_id ,
       var_person_id  ,
       var_concept_id ,
       var_encounter_id ,
       var_order_id ,
       var_obs_datetime,
       var_location_id ,
       var_obs_group_id ,
       var_accession_number ,
       var_value_group_id   ,
       var_value_boolean,
       var_value_coded   ,
       var_value_coded_name_id   ,
       var_value_drug   ,
       var_value_datetime,
       var_value_numeric,
       var_value_modifier,
       var_value_text,
       var_date_started,
       var_date_stopped,
       var_comments,
       var_creator,
       var_date_created,
       var_voided,
       var_voided_by,
       var_date_voided,
       var_void_reason,
       var_value_complex,
       var_uuid;

    # Check if we are done and exit loop if done
    IF done THEN

      LEAVE read_loop;

    END IF;

 INSERT INTO obs ( person_id  , concept_id, encounter_id, order_id, obs_datetime, location_id, obs_group_id   ,
  accession_number, value_group_id , value_boolean, value_coded, value_coded_name_id, value_drug, value_datetime,
  value_numeric, value_modifier, value_text, date_started, date_stopped, comments, creator, date_created,
  voided, voided_by, date_voided, void_reason, value_complex, uuid)
 VALUES ( var_person_id  , var_concept_id, new_enc_id, var_order_id, var_obs_datetime, var_location_id, var_obs_group_id   ,
  var_accession_number, var_value_group_id , var_value_boolean, var_value_coded, var_value_coded_name_id, var_value_drug, var_value_datetime,
  var_value_numeric, var_value_modifier, var_value_text, var_date_started, var_date_stopped, var_comments,var_creator, var_date_created,
  var_voided, var_voided_by, var_date_voided, var_void_reason, var_value_complex, var_uuid);

     UPDATE orders
     SET encounter_id = new_enc_id
     WHERE encounter_id = temp_enc_id
     AND patient_id = var_person_id;
  
   select var_person_id, var_encounter_id;
   END LOOP;

END$$

DELIMITER ;

