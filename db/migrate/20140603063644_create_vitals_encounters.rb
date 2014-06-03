class CreateVitalsEncounters < ActiveRecord::Migration
  def self.up

    ActiveRecord::Base.connection.execute <<EOF
	DROP TABLE IF EXISTS `vitals_encounters`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
create table `vitals_encounters`(
`id` int not null auto_increment primary key,
`visit_encounter_id` int not null,
`old_enc_id` int not null,
`patient_id` int not null,
`weight` float ,
`height` float,
`bmi` float,
`weight_for_age` float,
`height_for_age` float,
`weight_for_height` float,
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
    drop_table :vitals_encounters
  end
end
