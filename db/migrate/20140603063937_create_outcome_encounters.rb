class CreateOutcomeEncounters < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
drop table if exists `outcome_encounters`
EOF

    ActiveRecord::Base.connection.execute <<EOF
create table `outcome_encounters`(
`id` int not null auto_increment primary key,
`visit_encounter_id` int not null,
`old_enc_id` int not null,
`patient_id` int not null,
`state` varchar(255),
`outcome_date` date ,
`transferred_out_location` varchar(255),
`location` varchar(255),
`voided` int not null default 0,
`void_reason` varchar(255),
`date_voided` date,
`voided_by` int,
`encounter_datetime` datetime,
`date_created` datetime not null,
`creator` varchar(255) not null

);

EOF

  end

  def self.down
    drop_table :outcome_encounters
  end
end
