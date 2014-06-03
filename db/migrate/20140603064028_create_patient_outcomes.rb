class CreatePatientOutcomes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
drop table if exists `patient_outcomes`
EOF

    ActiveRecord::Base.connection.execute <<EOF
create table `patient_outcomes`(
`id` int not null auto_increment primary key,
`visit_encounter_id` int,
`outcome_id` int not null,
`patient_id` int not null,
`outcome_state` varchar(255),
`outcome_date` date

);

EOF

  end

  def self.down
    drop_table :patient_outcomes
  end

end
