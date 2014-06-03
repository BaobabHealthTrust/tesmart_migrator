class CreateFirstVisitEncounters < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
DROP table if exists `first_visit_encounters`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
 CREATE table `first_visit_encounters`(
 	`id` int not null auto_increment primary key,
	`visit_encounter_id` int not null,
	`old_enc_id` int not null,
	`patient_id` int not null,
	`agrees_to_follow_up` varchar(40),
	`date_of_hiv_pos_test` date,
	`date_of_hiv_pos_test_estimated` tinyint(1) default 0,
	`location_of_hiv_pos_test` varchar(255),
	`arv_number_at_that_site` varchar(255),
	`location_of_art_initiation` varchar(255),
	`taken_arvs_in_last_two_months` varchar(255),
	`taken_arvs_in_last_two_weeks`varchar(255),
	`has_transfer_letter`varchar(255),
	`site_transferred_from`varchar(255),
	`date_of_art_initiation` date,
	`ever_registered_at_art` varchar(25),
	`ever_received_arv` varchar(25),
	`last_arv_regimen` varchar(255),
	`date_last_arv_taken` date,
	`date_last_arv_taken_estimated` date,
	`weight` float,
	`height` float,
	`bmi` float,
	`location` varchar(255),
	`voided` tinyint(1) NOT NULL default 0,
	`void_reason` varchar(255),
	`date_voided` date,
	`voided_by` int (11),
	`encounter_datetime` datetime,
	`date_created` datetime not null,
	`creator` varchar(255)
 );
EOF
  end

  def self.down
    drop_table :first_visit_encounters
  end
end
