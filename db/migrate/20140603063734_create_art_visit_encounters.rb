class CreateArtVisitEncounters < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `art_visit_encounters`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
create table `art_visit_encounters` (
`id` int not null auto_increment primary key,
`visit_encounter_id` int not null,
`old_enc_id` int not null,
`patient_id` int not null,
`patient_pregnant` varchar(25),
`patient_breast_feeding` varchar(25),
`using_family_planning_method` varchar(25),
`family_planning_method_used` varchar(25),
`abdominal_pains` varchar(25),
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
`other_symptoms` varchar(25),
`drug_induced_Abdominal_pains` varchar(25),
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
`prescribe_arv` varchar(25),
`drug_name_brought_to_clinic1` varchar(255),
`drug_quantity_brought_to_clinic1` varchar(25),
`drug_left_at_home1` varchar(255),
`drug_name_brought_to_clinic2` varchar(255),
`drug_quantity_brought_to_clinic2` varchar(25),
`drug_left_at_home2` varchar(25),
`drug_name_brought_to_clinic3` varchar(255),
`drug_quantity_brought_to_clinic3` varchar(25),
`drug_left_at_home3` varchar(25),
`drug_name_brought_to_clinic4` varchar(255),
`drug_quantity_brought_to_clinic4` varchar(25),
`drug_left_at_home4` varchar(25),
`arv_regimen` varchar(255),
`prescribe_cpt` varchar(25),
`prescribe_ipt` varchar(25),
`number_of_condoms_given` int,
`depo_provera_given` varchar(25),
`continue_treatment_at_clinic` varchar(25),
`continue_art` varchar(25),
`location` varchar(255),
`voided` tinyint(1) not null default 0,
`void_reason` varchar(255),
`encounter_datetime` datetime,
`date_voided` date default null,
`voided_by` int(11),
`date_created` datetime default null,
`creator` varchar(255)

);
EOF

  end

  def self.down
    drop_table :art_visit_encounters
  end
end
