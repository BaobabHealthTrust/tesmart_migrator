class CreateHivReceptionEncounters < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
	DROP TABLE IF EXISTS `hiv_reception_encounters`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
create table `hiv_reception_encounters`(
`id` int not null auto_increment primary key,
`visit_encounter_id` int not null,
`old_enc_id` int not null,
`patient_id` int not null,
`guardian` int,
`patient_present` varchar(255),
`guardian_present` varchar(255),
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
    drop_table :hiv_reception_encounters
  end
end
