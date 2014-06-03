class CreateHivStagingEncounters < ActiveRecord::Migration
  def self.up

    ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `hiv_staging_encounters`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
create table `hiv_staging_encounters`(
`id` int auto_increment not null primary key,
`visit_encounter_id` int not null,
`old_enc_id` int not null,
`patient_id` int not null,
`patient_pregnant` varchar(25) ,
`patient_breast_feeding` varchar(25),
`cd4_count_available` varchar(25),
`cd4_count` int,
`cd4_count_modifier` varchar(5),
`cd4_count_percentage` double,
`date_of_cd4_count` date,
`asymptomatic` varchar(25),
`persistent_generalized_lymphadenopathy` varchar(25),
`unspecified_stage_1_cond` varchar(25),
`molluscumm_contagiosum` varchar(25),
`wart_virus_infection_extensive` varchar(25),
`oral_ulcerations_recurrent` varchar(25),
`parotid_enlargement_persistent_unexplained` varchar(25),
`lineal_gingival_erythema` varchar(25),
`herpes_zoster` varchar(25),
`respiratory_tract_infections_recurrent` varchar(25),
`unspecified_stage2_condition` varchar(25),
`angular_chelitis` varchar(25),
`papular_prurtic_eruptions` varchar(25),
`hepatosplenomegaly_unexplained` varchar(25),
`oral_hairy_leukoplakia` varchar(25),
`severe_weight_loss` varchar(25),
`fever_persistent_unexplained` varchar(25),
`pulmonary_tuberculosis` varchar(25),
`pulmonary_tuberculosis_last_2_years` varchar(25),
`severe_bacterial_infection` varchar(25),
`bacterial_pnuemonia` varchar(25),
`symptomatic_lymphoid_interstitial_pnuemonitis` varchar(25),
`chronic_hiv_assoc_lung_disease` varchar(25),
`unspecified_stage3_condition` varchar(25),
`aneamia` varchar(25),
`neutropaenia` varchar(25),
`thrombocytopaenia_chronic` varchar(25),
`diarhoea` varchar(25),
`oral_candidiasis` varchar(25),
`acute_necrotizing_ulcerative_gingivitis` varchar(25),
`lymph_node_tuberculosis` varchar(25),
`toxoplasmosis_of_brain` varchar(25),
`cryptococcal_meningitis` varchar(25),
`progressive_multifocal_leukoencephalopathy` varchar(25),
`disseminated_mycosis` varchar(25),
`candidiasis_of_oesophagus` varchar(25),
`extrapulmonary_tuberculosis` varchar(25),
`cerebral_non_hodgkin_lymphoma` varchar(25),
`kaposis` varchar(25),
`hiv_encephalopathy` varchar(25),
`bacterial_infections_severe_recurrent` varchar(25),
`unspecified_stage_4_condition` varchar(25),
`pnuemocystis_pnuemonia` varchar(25),
`disseminated_non_tuberculosis_mycobactierial_infection` varchar(25),
`cryptosporidiosis` varchar(25),
`isosporiasis` varchar(25),
`symptomatic_hiv_asscoiated_nephropathy` varchar(25),
`chronic_herpes_simplex_infection` varchar(25),
`cytomegalovirus_infection` varchar(25),
`toxoplasomis_of_the_brain_1month` varchar(25),
`recto_vaginal_fitsula` varchar(25),
`hiv_wasting_syndrome` varchar(25),
`reason_for_starting_art` varchar(25),
`who_stage` varchar(255),
`location` varchar(255),
`voided` tinyint(1) not null default 0,
`void_reason` varchar(255),
`date_voided` date,
`voided_by` int(11),
`encounter_datetime` datetime,
`date_created` datetime,
`creator` varchar(255)

);
EOF
  end

  def self.down
    drop_table :hiv_staging_encounters
  end
end
