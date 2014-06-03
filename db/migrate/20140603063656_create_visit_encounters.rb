class CreateVisitEncounters < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `visit_encounters`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
create table `visit_encounters`(
	`id` int NOT NULL auto_increment primary key,
	`visit_date` datetime NOT NULL default '0000-00-00',
	`patient_id` int not null
);
EOF
  end

  def self.down
    drop_table :visit_encounters
  end
end
