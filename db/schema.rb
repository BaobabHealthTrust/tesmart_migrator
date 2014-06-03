# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140603064901) do

  create_table "art_visit_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                                                  :null => false
    t.integer  "old_enc_id",                                                          :null => false
    t.integer  "patient_id",                                                          :null => false
    t.string   "patient_pregnant",                   :limit => 25
    t.string   "patient_breast_feeding",             :limit => 25
    t.string   "using_family_planning_method",       :limit => 25
    t.string   "family_planning_method_used",        :limit => 25
    t.string   "abdominal_pains",                    :limit => 25
    t.string   "anorexia",                           :limit => 25
    t.string   "cough",                              :limit => 25
    t.string   "diarrhoea",                          :limit => 25
    t.string   "fever",                              :limit => 25
    t.string   "jaundice",                           :limit => 25
    t.string   "leg_pain_numbness",                  :limit => 25
    t.string   "vomit",                              :limit => 25
    t.string   "weight_loss",                        :limit => 25
    t.string   "peripheral_neuropathy",              :limit => 25
    t.string   "hepatitis",                          :limit => 25
    t.string   "anaemia",                            :limit => 25
    t.string   "lactic_acidosis",                    :limit => 25
    t.string   "lipodystrophy",                      :limit => 25
    t.string   "skin_rash",                          :limit => 25
    t.string   "other_symptoms",                     :limit => 25
    t.string   "drug_induced_Abdominal_pains",       :limit => 25
    t.string   "drug_induced_anorexia",              :limit => 25
    t.string   "drug_induced_diarrhoea",             :limit => 25
    t.string   "drug_induced_jaundice",              :limit => 25
    t.string   "drug_induced_leg_pain_numbness",     :limit => 25
    t.string   "drug_induced_vomit",                 :limit => 25
    t.string   "drug_induced_peripheral_neuropathy", :limit => 25
    t.string   "drug_induced_hepatitis",             :limit => 25
    t.string   "drug_induced_anaemia",               :limit => 25
    t.string   "drug_induced_lactic_acidosis",       :limit => 25
    t.string   "drug_induced_lipodystrophy",         :limit => 25
    t.string   "drug_induced_skin_rash",             :limit => 25
    t.string   "drug_induced_other_symptom",         :limit => 25
    t.string   "tb_status"
    t.string   "refer_to_clinician",                 :limit => 25
    t.string   "prescribe_arv",                      :limit => 25
    t.string   "drug_name_brought_to_clinic1"
    t.string   "drug_quantity_brought_to_clinic1",   :limit => 25
    t.string   "drug_left_at_home1"
    t.string   "drug_name_brought_to_clinic2"
    t.string   "drug_quantity_brought_to_clinic2",   :limit => 25
    t.string   "drug_left_at_home2",                 :limit => 25
    t.string   "drug_name_brought_to_clinic3"
    t.string   "drug_quantity_brought_to_clinic3",   :limit => 25
    t.string   "drug_left_at_home3",                 :limit => 25
    t.string   "drug_name_brought_to_clinic4"
    t.string   "drug_quantity_brought_to_clinic4",   :limit => 25
    t.string   "drug_left_at_home4",                 :limit => 25
    t.string   "arv_regimen"
    t.string   "prescribe_cpt",                      :limit => 25
    t.string   "prescribe_ipt",                      :limit => 25
    t.integer  "number_of_condoms_given"
    t.string   "depo_provera_given",                 :limit => 25
    t.string   "continue_treatment_at_clinic",       :limit => 25
    t.string   "continue_art",                       :limit => 25
    t.string   "location"
    t.boolean  "voided",                                           :default => false, :null => false
    t.string   "void_reason"
    t.datetime "encounter_datetime"
    t.date     "date_voided"
    t.integer  "voided_by"
    t.datetime "date_created"
    t.string   "creator"
  end

  create_table "first_visit_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                                              :null => false
    t.integer  "old_enc_id",                                                      :null => false
    t.integer  "patient_id",                                                      :null => false
    t.string   "agrees_to_follow_up",            :limit => 40
    t.date     "date_of_hiv_pos_test"
    t.boolean  "date_of_hiv_pos_test_estimated",               :default => false
    t.string   "location_of_hiv_pos_test"
    t.string   "arv_number_at_that_site"
    t.string   "location_of_art_initiation"
    t.string   "taken_arvs_in_last_two_months"
    t.string   "taken_arvs_in_last_two_weeks"
    t.string   "has_transfer_letter"
    t.string   "site_transferred_from"
    t.date     "date_of_art_initiation"
    t.string   "ever_registered_at_art",         :limit => 25
    t.string   "ever_received_arv",              :limit => 25
    t.string   "last_arv_regimen"
    t.date     "date_last_arv_taken"
    t.date     "date_last_arv_taken_estimated"
    t.float    "weight"
    t.float    "height"
    t.float    "bmi"
    t.string   "location"
    t.boolean  "voided",                                       :default => false, :null => false
    t.string   "void_reason"
    t.date     "date_voided"
    t.integer  "voided_by"
    t.datetime "encounter_datetime"
    t.datetime "date_created",                                                    :null => false
    t.string   "creator"
  end

  create_table "general_reception_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                    :null => false
    t.integer  "old_enc_id",                            :null => false
    t.integer  "patient_id",                            :null => false
    t.string   "patient_present"
    t.string   "location"
    t.boolean  "voided",             :default => false, :null => false
    t.string   "void_reason"
    t.date     "date_voided"
    t.integer  "voided_by"
    t.datetime "encounter_datetime"
    t.datetime "date_created"
    t.string   "creator"
  end

  create_table "give_drugs_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                       :null => false
    t.integer  "old_enc_id",                               :null => false
    t.integer  "patient_id",                               :null => false
    t.string   "pres_drug_name1"
    t.string   "pres_dosage1"
    t.string   "pres_frequency1"
    t.string   "pres_drug_name2"
    t.string   "pres_dosage2"
    t.string   "pres_frequency2"
    t.string   "pres_drug_name3"
    t.string   "pres_dosage3"
    t.string   "pres_frequency3"
    t.string   "pres_drug_name4"
    t.string   "pres_dosage4"
    t.string   "pres_frequency4"
    t.string   "pres_drug_name5"
    t.string   "pres_dosage5"
    t.string   "pres_frequency5"
    t.string   "prescription_duration"
    t.string   "dispensed_drug_name1"
    t.string   "dispensed_dosage1"
    t.integer  "dispensed_quantity1"
    t.string   "dispensed_drug_name2"
    t.string   "dispensed_dosage2"
    t.integer  "dispensed_quantity2"
    t.string   "dispensed_drug_name3"
    t.string   "dispensed_dosage3"
    t.integer  "dispensed_quantity3"
    t.string   "dispensed_drug_name4"
    t.string   "dispensed_dosage4"
    t.integer  "dispensed_quantity4"
    t.string   "dispensed_drug_name5"
    t.string   "dispensed_dosage5"
    t.integer  "dispensed_quantity5"
    t.datetime "appointment_date"
    t.string   "regimen_category"
    t.string   "location"
    t.boolean  "voided",                :default => false, :null => false
    t.string   "void_reason"
    t.date     "date_voided"
    t.integer  "voided_by"
    t.datetime "encounter_datetime"
    t.datetime "date_created",                             :null => false
    t.string   "creator",                                  :null => false
  end

  create_table "guardians", :force => true do |t|
    t.integer "patient_id",                      :null => false
    t.integer "relative_id",                     :null => false
    t.string  "name"
    t.string  "relationship"
    t.string  "family_name"
    t.string  "gender"
    t.boolean "voided",       :default => false, :null => false
    t.string  "void_reason"
    t.date    "date_voided"
    t.integer "voided_by"
    t.date    "date_created",                    :null => false
    t.string  "creator",                         :null => false
  end

  create_table "hiv_reception_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                    :null => false
    t.integer  "old_enc_id",                            :null => false
    t.integer  "patient_id",                            :null => false
    t.integer  "guardian"
    t.string   "patient_present"
    t.string   "guardian_present"
    t.string   "location"
    t.boolean  "voided",             :default => false, :null => false
    t.string   "void_reason"
    t.date     "date_voided"
    t.integer  "voided_by"
    t.datetime "encounter_datetime"
    t.datetime "date_created"
    t.string   "creator"
  end

  create_table "hiv_staging_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                                                                      :null => false
    t.integer  "old_enc_id",                                                                              :null => false
    t.integer  "patient_id",                                                                              :null => false
    t.string   "patient_pregnant",                                       :limit => 25
    t.string   "patient_breast_feeding",                                 :limit => 25
    t.string   "cd4_count_available",                                    :limit => 25
    t.integer  "cd4_count"
    t.string   "cd4_count_modifier",                                     :limit => 5
    t.float    "cd4_count_percentage"
    t.date     "date_of_cd4_count"
    t.string   "asymptomatic",                                           :limit => 25
    t.string   "persistent_generalized_lymphadenopathy",                 :limit => 25
    t.string   "unspecified_stage_1_cond",                               :limit => 25
    t.string   "molluscumm_contagiosum",                                 :limit => 25
    t.string   "wart_virus_infection_extensive",                         :limit => 25
    t.string   "oral_ulcerations_recurrent",                             :limit => 25
    t.string   "parotid_enlargement_persistent_unexplained",             :limit => 25
    t.string   "lineal_gingival_erythema",                               :limit => 25
    t.string   "herpes_zoster",                                          :limit => 25
    t.string   "respiratory_tract_infections_recurrent",                 :limit => 25
    t.string   "unspecified_stage2_condition",                           :limit => 25
    t.string   "angular_chelitis",                                       :limit => 25
    t.string   "papular_prurtic_eruptions",                              :limit => 25
    t.string   "hepatosplenomegaly_unexplained",                         :limit => 25
    t.string   "oral_hairy_leukoplakia",                                 :limit => 25
    t.string   "severe_weight_loss",                                     :limit => 25
    t.string   "fever_persistent_unexplained",                           :limit => 25
    t.string   "pulmonary_tuberculosis",                                 :limit => 25
    t.string   "pulmonary_tuberculosis_last_2_years",                    :limit => 25
    t.string   "severe_bacterial_infection",                             :limit => 25
    t.string   "bacterial_pnuemonia",                                    :limit => 25
    t.string   "symptomatic_lymphoid_interstitial_pnuemonitis",          :limit => 25
    t.string   "chronic_hiv_assoc_lung_disease",                         :limit => 25
    t.string   "unspecified_stage3_condition",                           :limit => 25
    t.string   "aneamia",                                                :limit => 25
    t.string   "neutropaenia",                                           :limit => 25
    t.string   "thrombocytopaenia_chronic",                              :limit => 25
    t.string   "diarhoea",                                               :limit => 25
    t.string   "oral_candidiasis",                                       :limit => 25
    t.string   "acute_necrotizing_ulcerative_gingivitis",                :limit => 25
    t.string   "lymph_node_tuberculosis",                                :limit => 25
    t.string   "toxoplasmosis_of_brain",                                 :limit => 25
    t.string   "cryptococcal_meningitis",                                :limit => 25
    t.string   "progressive_multifocal_leukoencephalopathy",             :limit => 25
    t.string   "disseminated_mycosis",                                   :limit => 25
    t.string   "candidiasis_of_oesophagus",                              :limit => 25
    t.string   "extrapulmonary_tuberculosis",                            :limit => 25
    t.string   "cerebral_non_hodgkin_lymphoma",                          :limit => 25
    t.string   "kaposis",                                                :limit => 25
    t.string   "hiv_encephalopathy",                                     :limit => 25
    t.string   "bacterial_infections_severe_recurrent",                  :limit => 25
    t.string   "unspecified_stage_4_condition",                          :limit => 25
    t.string   "pnuemocystis_pnuemonia",                                 :limit => 25
    t.string   "disseminated_non_tuberculosis_mycobactierial_infection", :limit => 25
    t.string   "cryptosporidiosis",                                      :limit => 25
    t.string   "isosporiasis",                                           :limit => 25
    t.string   "symptomatic_hiv_asscoiated_nephropathy",                 :limit => 25
    t.string   "chronic_herpes_simplex_infection",                       :limit => 25
    t.string   "cytomegalovirus_infection",                              :limit => 25
    t.string   "toxoplasomis_of_the_brain_1month",                       :limit => 25
    t.string   "recto_vaginal_fitsula",                                  :limit => 25
    t.string   "hiv_wasting_syndrome",                                   :limit => 25
    t.string   "reason_for_starting_art",                                :limit => 25
    t.string   "who_stage"
    t.string   "location"
    t.boolean  "voided",                                                               :default => false, :null => false
    t.string   "void_reason"
    t.date     "date_voided"
    t.integer  "voided_by"
    t.datetime "encounter_datetime"
    t.datetime "date_created"
    t.string   "creator"
  end

  create_table "outcome_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                      :null => false
    t.integer  "old_enc_id",                              :null => false
    t.integer  "patient_id",                              :null => false
    t.string   "state"
    t.date     "outcome_date"
    t.string   "transferred_out_location"
    t.string   "location"
    t.integer  "voided",                   :default => 0, :null => false
    t.string   "void_reason"
    t.date     "date_voided"
    t.integer  "voided_by"
    t.datetime "encounter_datetime"
    t.datetime "date_created",                            :null => false
    t.string   "creator",                                 :null => false
  end

  create_table "outpatient_diagnosis_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                      :null => false
    t.integer  "old_enc_id",                              :null => false
    t.integer  "patient_id",                              :null => false
    t.string   "refer_to_anotha_hosp"
    t.string   "pri_diagnosis"
    t.string   "sec_diagnosis"
    t.string   "treatment1"
    t.string   "treatment2"
    t.string   "treatment3"
    t.string   "treatment4"
    t.string   "treatment5"
    t.string   "location"
    t.boolean  "voided",               :default => false, :null => false
    t.string   "void_reason"
    t.date     "date_voided"
    t.integer  "voided_by"
    t.datetime "encounter_datetime"
    t.datetime "date_created"
    t.string   "creator"
  end

  create_table "patient_outcomes", :force => true do |t|
    t.integer "visit_encounter_id"
    t.integer "outcome_id",         :null => false
    t.integer "patient_id",         :null => false
    t.string  "outcome_state"
    t.date    "outcome_date"
  end

  create_table "patients", :primary_key => "patient_id", :force => true do |t|
    t.string  "given_name"
    t.string  "middle_name"
    t.string  "family_name"
    t.string  "gender",                 :limit => 25
    t.date    "dob"
    t.text    "dob_estimated"
    t.integer "dead"
    t.string  "traditional_authority"
    t.string  "current_address"
    t.string  "landmark"
    t.string  "cellphone_number"
    t.string  "home_phone_number"
    t.string  "office_phone_number"
    t.string  "occupation"
    t.integer "guardian_id"
    t.string  "nat_id"
    t.string  "art_number"
    t.string  "pre_art_number"
    t.string  "tb_number"
    t.string  "legacy_id"
    t.string  "legacy_id2"
    t.string  "legacy_id3"
    t.string  "new_nat_id"
    t.string  "prev_art_number"
    t.string  "filing_number"
    t.string  "archived_filing_number"
    t.boolean "voided",                               :default => false, :null => false
    t.string  "void_reason"
    t.date    "date_voided"
    t.integer "voided_by"
    t.date    "date_created",                                            :null => false
    t.string  "creator",                                                 :null => false
  end

  create_table "pre_art_visit_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                               :null => false
    t.integer  "old_enc_id",                                       :null => false
    t.integer  "patient_id",                                       :null => false
    t.string   "patient_pregnant",                   :limit => 25
    t.string   "patient_breast_feeding",             :limit => 25
    t.string   "abdominal_pains",                    :limit => 25
    t.string   "using_family_planning_method",       :limit => 25
    t.string   "family_planning_method_in_use"
    t.string   "anorexia",                           :limit => 25
    t.string   "cough",                              :limit => 25
    t.string   "diarrhoea",                          :limit => 25
    t.string   "fever",                              :limit => 25
    t.string   "jaundice",                           :limit => 25
    t.string   "leg_pain_numbness",                  :limit => 25
    t.string   "vomit",                              :limit => 25
    t.string   "weight_loss",                        :limit => 25
    t.string   "peripheral_neuropathy",              :limit => 25
    t.string   "hepatitis",                          :limit => 25
    t.string   "anaemia",                            :limit => 25
    t.string   "lactic_acidosis",                    :limit => 25
    t.string   "lipodystrophy",                      :limit => 25
    t.string   "skin_rash",                          :limit => 25
    t.string   "drug_induced_abdominal_pains",       :limit => 25
    t.string   "drug_induced_anorexia",              :limit => 25
    t.string   "drug_induced_diarrhoea",             :limit => 25
    t.string   "drug_induced_jaundice",              :limit => 25
    t.string   "drug_induced_leg_pain_numbness",     :limit => 25
    t.string   "drug_induced_vomit",                 :limit => 25
    t.string   "drug_induced_peripheral_neuropathy", :limit => 25
    t.string   "drug_induced_hepatitis",             :limit => 25
    t.string   "drug_induced_anaemia",               :limit => 25
    t.string   "drug_induced_lactic_acidosis",       :limit => 25
    t.string   "drug_induced_lipodystrophy",         :limit => 25
    t.string   "drug_induced_skin_rash",             :limit => 25
    t.string   "drug_induced_other_symptom",         :limit => 25
    t.string   "tb_status"
    t.string   "refer_to_clinician",                 :limit => 25
    t.string   "prescribe_cpt",                      :limit => 25
    t.string   "prescription_duration",              :limit => 25
    t.integer  "number_of_condoms_given"
    t.string   "prescribe_ipt",                      :limit => 25
    t.datetime "encounter_datetime"
    t.datetime "date_created"
    t.string   "location"
    t.string   "creator"
  end

  create_table "visit_encounters", :force => true do |t|
    t.datetime "visit_date", :null => false
    t.integer  "patient_id", :null => false
  end

  create_table "vitals_encounters", :force => true do |t|
    t.integer  "visit_encounter_id",                    :null => false
    t.integer  "old_enc_id",                            :null => false
    t.integer  "patient_id",                            :null => false
    t.float    "weight"
    t.float    "height"
    t.float    "bmi"
    t.float    "weight_for_age"
    t.float    "height_for_age"
    t.float    "weight_for_height"
    t.string   "location"
    t.boolean  "voided",             :default => false, :null => false
    t.string   "void_reason"
    t.date     "date_voided"
    t.integer  "voided_by"
    t.datetime "encounter_datetime"
    t.datetime "date_created"
    t.string   "creator"
  end

end
