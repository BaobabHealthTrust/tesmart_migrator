class CreateOutpatientDiagnosisEncounters < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
 	DROP TABLE IF EXISTS `outpatient_diagnosis_encounters`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
create table `outpatient_diagnosis_encounters`(
`id` int not null auto_increment primary key,
`visit_encounter_id` int not null,
`old_enc_id` int not null,
`patient_id` int not null,
`refer_to_anotha_hosp` varchar(255),
`pri_diagnosis` varchar(255),
`sec_diagnosis` varchar(255),
`treatment1` varchar(255),
`treatment2` varchar(255),
`treatment3` varchar(255),
`treatment4` varchar(255),
`treatment5` varchar(255),
`location` varchar(255),
`voided` tinyint(1) not null default 0,
`void_reason` varchar(255),
`date_voided` date default null,
`voided_by` int(11),
`encounter_datetime` datetime,
`date_created` datetime default null,
`creator` varchar(255)
);

EOF

  end


  def self.down
    drop_table :outpatient_diagnosis_encounters
  end
end
