DELIMITER $$

	DROP PROCEDURE IF EXISTS `proc_update_obs_order_id`$$

	CREATE PROCEDURE `proc_update_obs_order_id`()

	BEGIN



		DECLARE var_drug_id INT(11);
		DECLARE var_obs_id INT(11);
		DECLARE var_obs_date DATETIME;
		DECLARE var_person_id INT(11);
		DECLARE done INT DEFAULT FALSE;
		DECLARE obs CURSOR FOR SELECT obs_id,person_id, value_drug, obs_datetime FROM obs WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name ="AMOUNT OF DRUG BROUGHT TO CLINIC" LIMIT 1);
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;	
		SET @amount_dispensed_concept_id = (SELECT concept_id FROM concept_name WHERE name ="AMOUNT DISPENSED" LIMIT 1);
		
		OPEN obs;
		
		read_loop : LOOP
		
		FETCH obs INTO var_obs_id, var_person_id, var_drug_id, var_obs_date;
		
		IF done THEN
		
			LEAVE read_loop;
			
		END IF;
		
		
		SET @order_id = (SELECT obs.order_id FROM obs INNER JOIN drug_order ON obs.order_id = drug_order.order_id 
											WHERE concept_id = @amount_dispensed_concept_id AND person_id = var_person_id 
											AND value_drug = var_drug_id AND DATE(obs_datetime) < DATE(var_obs_date) 
											ORDER BY obs_datetime DESC,equivalent_daily_dose DESC  LIMIT 1);
		
		
		IF NOT ISNULL(@order_id) THEN
		
			UPDATE obs SET order_id = @order_id WHERE obs_id = var_obs_id;
		
		END IF;
		select var_person_id, var_drug_id;
		END LOOP;
		
		CLOSE obs;

	END$$

DELIMITER ;
