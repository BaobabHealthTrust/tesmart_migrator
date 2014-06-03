class CreateGiveDrugsEncounters < ActiveRecord::Migration
  def self.up

    ActiveRecord::Base.connection.execute <<EOF
drop table if exists `give_drug_encounters`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
create table `give_drugs_encounters`(
`id` int not null auto_increment primary key,
`visit_encounter_id` int not null,
`old_enc_id` int not null,
`patient_id` int not null,
`pres_drug_name1` varchar(255),
`pres_dosage1` varchar(255),
`pres_frequency1` varchar(255),
`pres_drug_name2` varchar(255),
`pres_dosage2` varchar(255),
`pres_frequency2` varchar(255),
`pres_drug_name3` varchar(255),
`pres_dosage3` varchar(255),
`pres_frequency3` varchar(255),
`pres_drug_name4` varchar(255),
`pres_dosage4` varchar(255),
`pres_frequency4` varchar(255),
`pres_drug_name5` varchar(255),
`pres_dosage5` varchar(255),
`pres_frequency5` varchar(255),
`prescription_duration` varchar(255),
`dispensed_drug_name1` varchar(255),
`dispensed_dosage1` varchar(255),
`dispensed_quantity1` int,
`dispensed_drug_name2` varchar(255),
`dispensed_dosage2` varchar(255),
`dispensed_quantity2` int,
`dispensed_drug_name3` varchar(255),
`dispensed_dosage3` varchar(255),
`dispensed_quantity3` int,
`dispensed_drug_name4` varchar(255),
`dispensed_dosage4` varchar(255),
`dispensed_quantity4` int,
`dispensed_drug_name5` varchar(255),
`dispensed_dosage5` varchar(255),
`dispensed_quantity5` int,
`appointment_date` datetime,
`regimen_category` varchar(255),
`location` varchar(255),
`voided` tinyint(1) not null default 0,
`void_reason` varchar(255),
`date_voided` date ,
`voided_by` int,
`encounter_datetime` datetime,
`date_created` datetime not null,
`creator` varchar(255) not null
);
EOF
  end

  def self.down
    drop_table :give_drugs_encounters
  end
end
