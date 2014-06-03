class CreatePreArtVisitEncounters < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
	drop table if exists `pre_art_visit_encounters`;

EOF

    ActiveRecord::Base.connection.execute <<EOF
	create table `pre_art_visit_encounters` (
`id` int not null auto_increment primary key,
`visit_encounter_id` int not null,
`old_enc_id` int not null,
`patient_id` int(11) not null,
`patient_pregnant` varchar(25),
`patient_breast_feeding` varchar(25),
`abdominal_pains` varchar(25),
`using_family_planning_method` varchar(25),
`family_planning_method_in_use` varchar(255),
`anorexia` varchar(25),
`cough` varchar(25),
`diarrhoea` varchar(25),
`fever` varchar(25),
`jaundice` varchar(25),
`leg_pain_numbness` varchar(25),
`vomit` varchar(25),
`weight_loss` varchar(25),
`peripheral_neuropathy` varchar(25),
`hepatitis` varchar(25),
`anaemia` varchar(25),
`lactic_acidosis` varchar(25),
`lipodystrophy` varchar(25),
`skin_rash` varchar(25),
`drug_induced_abdominal_pains` varchar(25),
`drug_induced_anorexia` varchar(25),
`drug_induced_diarrhoea` varchar(25),
`drug_induced_jaundice` varchar(25),
`drug_induced_leg_pain_numbness` varchar(25),
`drug_induced_vomit` varchar(25),
`drug_induced_peripheral_neuropathy` varchar(25),
`drug_induced_hepatitis` varchar(25),
`drug_induced_anaemia` varchar(25),
`drug_induced_lactic_acidosis` varchar(25),
`drug_induced_lipodystrophy` varchar(25),
`drug_induced_skin_rash` varchar(25),
`drug_induced_other_symptom` varchar(25),
`tb_status` varchar(255),
`refer_to_clinician` varchar(25),
`prescribe_cpt` varchar(25),
`prescription_duration` varchar(25),
`number_of_condoms_given` int ,
`prescribe_ipt` varchar(25),
`encounter_datetime` datetime,
`date_created` datetime default null,
`location` varchar(255),
`creator` varchar(255)

	);
EOF

  end

  def self.down
    drop_table :pre_art_visit_encounters
  end
end
