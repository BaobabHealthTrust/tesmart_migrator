$person_id = 2
$encounter_id = 1
$visit_encounter_hash = {}
$hospital_id = 214
$drug_code = {"TDF3TC"=>[734,"TDF/3TC (Tenofavir and Lamivudine 300/300mg tablet","IN THE EVENING",1,7928],
             "CPT"=>[297,"Cotrimoxazole (480mg tablet)","TWICE A DAY (BD)", 1,916],
             "CO"=>[297,"Cotrimoxazole (480mg tablet)","TWICE A DAY (BD)", 1,916],
             "CTX"=>[576,"Cotrimoxazole (960mg tablet)","IN THE EVENING (QPM)",1,916],
             "ATV/r_A"=>[817,"atr/A 100/200mg","IN THE EVENING (QPM)",1,8384],
             "L3015_A"=>[613,"d4T/3TC/NVP (30/150/200mg tablet)","ONCE A DAY (od)",1,792],
             "T3060_A"=>[613,"d4T/3TC/NVP (30/150/200mg tablet)","TWICE A DAY(BD)",1,792],
             "AZT3TCN_A"=>[731,"AZT/3TC/NVP (300/150/200mg tablet)","TWICE A DAY (BD)",1,1610],
             "AZT3TCN_P"=>[732,"AZT/3TC/NVP (60/30/50mg tablet)","TWICE A DAY (BD)",1,1610],
             "TDF3TCEFV"=>[735,"TDF/3TC/EFV (300/300/600mg tablet)","IN THE EVENING (QPM)",1,2985],
             "L3015_P"=>[72,"Triomune baby (d4T/3TC/NVP 6/30/50mg tablet)","TWICE A DAY(BD)",1,2985],
             "AZT3TCN_P"=>[732,"AZT/3TC/NVP (60/30/50mg tablet)","TWICE A DAY (BD)",1,1610],
             "ABC3TC"=>[733,"ABC/3TC (Abacavir and Lamivudine 60/30mg tablet)","TWICE A DAY (BD)",4,7927],
             "AZT3TC_A"=>[731,"AZT/3TC/NVP (300/150/200mg tablet)","TWICE A DAY (BD)",1,1610],
             "AZT3TC_P"=>[732,"AZT/3TC/NVP (60/30/50mg tablet)","TWICE A DAY (BD)",1,1610],
             "LPVr_P"=>[74,"LPV/r (Lopinavir and Ritonavir 100/25mg tablet)","TWICE A DAY (BD)",2,794],
             "LPVr_A"=>[73,"LPV/r (Lopinavir and Ritonavir 200/50mg tablet)","TWICE A DAY (BD)",2,794],
             "L3060_P"=>[737,"d4T/3TC (Stavudine Lamivudine 6/30mg tablet)","ONCE A DAY (od)",1,2833],
             "L3060_A"=>[738,"d4T/3TC (Stavudine Lamivudine 30/150 tablet)","ONCE A DAY (od)",1,2833],
             "T3060_P"=>[72,"Triomune baby (d4T/3TC/NVP 6/30/50mg tablet)","IN THE EVENING (QPM)",1,792],
             "T3015_A"=>[613,"d4T/3TC/NVP (30/150/200mg tablet)","IN THE EVENING (QPM)",1,792],
             "T3015_P"=>[737,"d4T/3TC/NVP (Stavudine Lamivudine 6/30mg/50mg tablet","IN THE EVENING (QPM)",1,2833],
             "EFV_A"=>[11,"EFV (Efavirenz 600mg tablet)","IN THE EVENING (QPM)",1,633],
             "EFV_P"=>[30,"EFV (Efavirenz 200mg tablet)","IN THE EVENING (QPM)",1,633],
             "NVP"=>[22,"NVP (Nevirapine 200 mg tablet)","TWICE A DAY (BD)",1,631],
             "IPT"=>[24,"INH or H (Isoniazid 100mg tablet)","IN THE EVENING (QPM)",1,656] }


def start
  patients = TesmartPatient.all
  count = patients.length

  traditional_authorities =  TesmartLookup.load_traditional_authority

  @traditionalauthoritydata = Hash.new("unknown")

  traditional_authorities.each do |ta|
     @traditionalauthoritydata[ta.item_code] = ta.code_desc
  end

  occupation = TesmartLookup.load_occupation_data
  @occupationdata = Hash.new("Missing")

  occupation.each do |occ|
	  @occupationdata[occ.item_code] = occ.code_desc
  end

  villages = TesmartLookup.load_villages

  @villagedata = Hash.new("unknown")

  villages.each do |vil|
     @villagedata[vil.item_code] = vil.code_desc
  end

  puts "Patients to be migrated #{count}"

  (patients || []).each do |patient|
    next if patient.id == 0
    puts "Working on patient id #{patient.id}, #{count} patients left"
    patient_id = create_patient(patient)

    if !patient_id.blank?
      staging = TesmartStaging.find(:last,:order => "clinicday ASC",
                                    :conditions =>["arv_no = ?", patient.id])

      #create_hiv_staging_encounter(staging,patient,patient_id)
#      create_first_visit_encounter
      process_patient_records(patient, patient_id)
    end
    count -= 1

  end

end

def create_patient(t_patient)
  new_patient = Patient.new
  new_patient.patient_id = $person_id
  new_patient.given_name = t_patient.F_name
  new_patient.family_name = t_patient.L_name
  if t_patient.Sex = '1'
  new_patient.gender = 'M'
  else
  new_patient.gender = 'F'
  end
  new_patient.dob = "#{t_patient.birth_year}" + "-" + "#{t_patient.birth_month}" + "-" + "#{t_patient.birth_Day}"
  if t_patient.DateOfDeath.blank?
  new_patient.dead = 0
  else
   new_patient.dead = 1
  end 
  if t_patient.TA.blank? 
	t_patient.TA = "Unknown"
  end  
  new_patient.traditional_authority = @traditionalauthoritydata[t_patient.TA]
  #Add more  
  if t_patient.Village.blank?
	t_patient.Village = "Unknown"
  end
  new_patient.current_address = @villagedata[t_patient.Village]
  new_patient.cellphone_number = t_patient.CellPhone
  new_patient.occupation = @occupationdata[t_patient.Occupation]
  new_patient.guardian_id = ''
  new_patient.art_number = "#{t_patient.h_code}" + "-" + "ARV" + "-" + "#{t_patient.arv_no}"
  new_patient.voided = 0
  new_patient.creator = 1
  new_patient.date_created = t_patient.cdate
  new_patient.home_phone_number = t_patient.HomePhone
  new_patient.dob_estimated = 0
  new_patient.landmark = t_patient.Address

  if new_patient.save
    $person_id +=1
    create_guardian(t_patient, new_patient.id)
    return new_patient.id
  else
    return false
  end
end

def create_guardian(t_patient, patient_id)

  guardian_names = t_patient.GuardianName.split(" ")
  gender = get_relation_gender(t_patient.Sex, t_patient.guardianrelation)
  new_guardian_patient = Patient.new
  new_guardian_patient.patient_id = $person_id
  new_guardian_patient.given_name = guardian_names.first
  new_guardian_patient.family_name = guardian_names.last
  new_guardian_patient.gender = gender
  new_guardian_patient.dob = '0000-00-00'
  new_guardian_patient.voided = 0
  new_guardian_patient.creator = 1
  new_guardian_patient.date_created = t_patient.cdate
  new_guardian_patient.save
  $person_id +=1

  new_guardian = Guardian.new
  new_guardian.patient_id = patient_id
  new_guardian.relative_id = new_guardian_patient.patient_id
  new_guardian.relationship = get_relationship(t_patient)
  new_guardian.name = guardian_names.first
  new_guardian.family_name = guardian_names.last
  new_guardian.gender = gender
  new_guardian.creator = 1
  new_guardian.voided = 0
  new_guardian.date_created = t_patient.cdate
  new_guardian.save

  patient = Patient.find(patient_id)
  patient.guardian_id = new_guardian_patient.patient_id
  patient.save
end


def process_patient_records(patient, patient_id)
  $outcome_encounter = 1
  $p_outcome_id = 1
  visit_records = TesmartOpdReg.find(:all, :conditions => ["arv_no = ? ", patient.id] )
  #bart_patient = Patient.find(patient_id)
  (visit_records || []).each do |record|
    #height = get_patient_height(record)
    create_outcome(record,patient_id)
    create_outcome_encounter(record, patient_id,record.cdate)
    create_art_visit(record,patient,bart_patient)
    create_give_drugs_encounter(record.ClinicDay, patient, patient_id)

    #create_vitals_encounter(record.Weight,height, patient_id, record.cdate, record.ClinicDay)
    #create_hiv_reception_encounter(bart_patient,record.ARVGiven,record.cdate, record.ClinicDay)
  end


end

def create_outcome(t_rec,patient_id)
  #by justin

     outcome = OutcomeEncounter.new
     outcome.visit_encounter_id = create_visit_encounter(t_rec.ClinicDay,patient_id)
     outcome.old_enc_id = $encounter_id
     outcome.patient_id =  patient_id
     outcome.state = get_status(t_rec.OutcomeStatus )
     outcome.outcome_date =  t_rec.ClinicDay
     if !(t_rec.TransferOutTo.blank?)
     outcome.transferred_out_location = get_location(t_rec.TransferOutTo)
     end
     outcome.location = $hospital_id
     outcome.voided = 0
     outcome.encounter_datetime = t_rec.ClinicDay
     outcome.date_created = t_rec.cdate
     outcome.creator = 1
     outcome.save
     $encounter_id += 1

end

def create_first_visit_encounter(t_patient, patient_id)

  new_first_visit_enc = FirstVisitEncounter.new
  new_first_visit_enc.agrees_to_follow_up = get_followup_status(t_patient, record)
  new_first_visit_enc.date_of_hiv_pos_test = t_patient.HIV_Positive_Date
  new_first_visit_enc.date_of_art_initiation = t_patient.FirstLineARV

  if record.HIV_Positive_Place.blank?
    new_first_visit_enc.location_of_hiv_pos_test = t_patient.HIV_Positive_Place_text.blank? ? "Unknown" : t_patient.HIV_Positive_Place_text
  else
    new_first_visit_enc.location_of_hiv_pos_test = TesmartLookup.find_by_item_code(t_patient.HIV_Positive_Place).code_desc rescue "Unknown"
  end

  if t_patient.TransferIn == "TI"
    new_first_visit_enc.has_transfer_letter = "Yes"
    new_first_visit_enc.site_transferred_from = t_patient.Transferinsite.blank? ? "Unknown" : get_location(t_patient.Transferinsite)
  end

  if (t_patient.TransferIn == "TI" || t_patient.TransferIn == "RI")
    new_first_visit_enc.arv_number_at_that_site = "#{t_patient.h_code}" + "-" + "ARV" + "-" + "#{t_patient.arv_no}"
    # new_first_visit_enc.taken_arvs_in_last_two_months = "" key variable not collected
    # new_first_visit_enc.taken_arvs_in_last_two_weeks = "" key variable not collected
    new_first_visit_enc.ever_registered_at_art = "Yes"
    new_first_visit_enc.ever_received_arv = "Yes"
    new_first_visit_enc.last_arv_regimen = t_patient.Last_arvDrug
    new_first_visit_enc.date_last_arv_taken =  t_patient.Last_arvDate unless (t_patient.Last_arvDate.blank? || t_patient.Last_arvDate.to_date == "1899-12-30".to_date)
  end

  new_first_visit_enc.location_of_art_initiation = get_location(t_patient.FirstLineARVsite.blank? ? $hospital_id : t_patient.FirstLineARVsite)
	new_first_visit_enc.weight = t_patient.Weight
	new_first_visit_enc.height = t_patient.Height
	new_first_visit_enc.bmi = (t_patient.weight.to_f/(t_patient.height.to_f*t_patient.height.to_f)*10000) rescue nil
  new_first_visit_enc.patient_id = patient_id
  new_first_visit_enc.old_enc_id = $encounter_id
  new_first_visit_enc.visit_encounter_id = create_visit_encounter(t_patient.DateOfBegin,patient_id)
  new_first_visit_enc.voided = 0
  new_first_visit_enc.date_created = cdate
  new_first_visit_enc.encounter_datetime = t_patient.DateOfBegin
  new_first_visit_enc.creator = 1
  new_first_visit_enc.save
  $encounter_id += 1
end

def create_hiv_staging_encounter(t_stage, t_patient, patient_id)
  sssssss#by temwa
  new_staging = HivStagingEncounter.new
  new_staging.patient_id = patient_id
  new_staging.patient_pregnant = t_stage.a3
  new_staging.patient_breast_feeding = t_stage.a4
  new_staging.cd4_count = t_patient.initCD4Count
  new_staging.date_of_cd4_count = t_patient.initCD4Date #check!!!
  new_staging.asymptomatic = t_stage.a1
  new_staging.persistent_generalized_lymphadenopathy = t_stage.a2
 # new_staging.unspecified_stage_1_cond = Null
  new_staging.molluscum_contagiosum = t_stage.b54
  new_staging.wart_virus_infection_extensive = t_stage.b53
  new_staging.oral_ulcerations_recurrent = t_stage.b55
  new_staging.parotid_enlargement_persistent_unexplained = t_stage.b56
  new_staging.lineal_gingival_erythema = t_stage.b57
  new_staging.herpes_zoster = t_stage.b5867
  new_staging.respiratory_tract_infection_recurrent = t_stage.b5968
  #new_staging.unspecified_stage2_condition= Null
  new_staging.angular_chelitis = t_stage.b2
  new_staging.papular_prutic_eruptions = t_stage.b6169
  new_staging.hepatosplenomegaly_unexplained = t_stage.b51
  new_staging.oral_hairy_leukoplakia =t_stage.c2
  new_staging.severe_weight_loss = t_stage.c3
  new_staging.fever_persistent_unexplained = t_stage.c5
  new_staging.pulmonary_tubercuosis = t_stage.c6
  new_staging.pulmonary_tuberculosis_last_2_years = t_stage.c7
  new_staging.severe_bacterial_infection = t_stage.c8
  new_staging.bacterial_pnuemonia = t_stage.c53
  new_staging.symptomatic_lymphoid_interstitial_pnuemonitis = t_stage.c54
  new_staging.chronic_hiv_assoc_lung_disease = t_stage.c55
  #new_staging.unspecified_stage3_conditions = Null
  new_staging.aneamia = t_stage.c10_1
  new_staging.neutropaenia = t_stage.c10_2
  new_staging.thrombocytopaenia_chronic = t_stage.c10_3
  new_staging.diarhoea = t_stage.c4
  new_staging.oral_candidiasis = t_stage.c1
  new_staging.acute_necrotizing_ulcerative_gingivitis = t_stage.c9
  new_staging.lymph_node_tuberculosis = t_stage.c52
  new_staging.toxoplasmosis_of_brain = t_stage.d3
  new_staging.cryptococcal_meningitis = t_stage.d6
  new_staging.progressive_multifocal_leukoencephalopathy = t_stage,d9
  new_staging.disseminated_mycosis = t_stage.d10
  new_staging.candidiasis_of_oesophagus = t_stage.d11
  new_staging.extrapulmonary_tuberculosis = t_stage.d14
  new_staging.cerebral_non_hodgkin_lymphoma = t_stage.d15
  new_staging.kaposis = t_stage.d16
  new_staging.hiv_encephalopathy = t_stage.d17
  new_staging.bacterial_infections_severe_recurrent = t_stage.d5
  #new_staging.unspecified_stage_4_condition = Null
  new_staging.pnuemocystis_pnuemonia = t_stage.d2
  new_staging.disseminated_non_tuberculosis_mycobacterial_infection = t_stage.d12
  new_staging.cryptosporidiosis = t_stage.d4
  new_staging.isosporiasis = t_stage.d4_1
  new_staging.symptomatic_hiv_associated_nephropathy = t_stage.dh1
  new_staging.chronic_herpes_simplex_infection = t_stage.d8
  new_staging.cutomegalovirus_infection = t_stage.d7
  new_staging.toxoplasomis_of_the_brain_1month  = t_stage.d3
  new_staging.recto_varginal_fistula = t_stage.dn2
  new_staging.hiv_wasting_syndrome = t_stage.d1
  new_staging.who_stage = t_stage.staging
  new_staging.date_created  = t_stage.cdate
  new_staging.old.enc_id = $encounter_id
  new_staging.visit_encounter_id = create_visit_encounter(t_stage.clinicday, patient_id)
  new_staging.save
  $encounter_id +=1

end

def create_hiv_reception_encounter(patient,present,date_created, enc_date)
  new_recp_encounter = HivReceptionEncounter.new

  if present = "B"
    new_recp_encounter.guardian = patient.gaurdian.relative_id rescue nil
    new_recp_encounter.guardian_present = "Yes"
    new_recp_encounter.patient_present = "Yes"
  elsif present = "G"
    new_recp_encounter.guardian = patient.gaurdian.relative_id rescue nil
    new_recp_encounter.guardian_present = "Yes"
  else
    new_recp_encounter.patient_present = "Yes"
  end
  new_recp_encounter.visit_encounter_id = create_visit_encounter(enc_date,patient.id)
  new_recp_encounter.patient_id = patient.id
  new_recp_encounter.old_enc_id = $encounter_id
  new_recp_encounter.creator = 1
  new_recp_encounter.encounter_datetime = enc_date
  new_recp_encounter.date_created = date_created
  new_recp_encounter.voided = 0
  new_recp_encounter.save

  $encounter_id += 1
end

def create_vitals_encounter(weight, height, patient_id, cdate, enc_date)

  new_vitals_enc = VitalsEncounter.new
  new_vitals_enc.patient_id = patient_id
  new_vitals_enc.weight = weight
  unless height == 0
    new_vitals_enc.height = height
    new_vitals_enc.bmi = (weight.to_f/(height.to_f*height.to_f)*10000) rescue nil
  end
  new_vitals_enc.visit_encounter_id = $visit_encounter_hash["#{patient_id}#{enc_date}"].blank? ? create_visit_encounter(enc_date,patient_id) : $visit_encounter_hash["#{patient_id}#{enc_date}"]
  new_vitals_enc.old_enc_id = $encounter_id
  new_vitals_enc.voided = 0
  new_vitals_enc.date_created = cdate
  new_vitals_enc.encounter_datetime = enc_date
  new_vitals_enc.creator = 1
  new_vitals_enc.save
  $encounter_id += 1

end

def create_give_drugs_encounter(clinic_day, t_patient, patient_id)
  #by justin
  #tesmart to openmrs drug mapping
  dispensation_records = TesmartOpdTran.find(:all,
                                             :conditions => ["arv_no = ? AND ClinicDay = ? ", t_patient.id, clinic_day])
  unless dispensation_records.blank?
    new_give_drug_enc = GiveDrugsEncounter.new
    drug_no = 1
    (dispensation_records || []).each do |drug_disp|
        case drug_no
          when 1
            new_give_drug_enc.pres_drug_name1 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.pres_dosage1 = drug_disp.take_qty
            new_give_drug_enc.pres_frequency1 = get_drug_frequency(drug_code[drug_disp.item_code][2])
            new_give_drug_enc.dispensed_drug_name1 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage1 = drug_disp.take_qty
            new_give_drug_enc.dispensed_quantity1 = drug_disp.qty
          when 2
            new_give_drug_enc.pres_drug_name2 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.pres_dosage2 = drug_disp.take_qty
            new_give_drug_enc.pres_frequency2 = get_drug_frequency(drug_code[drug_disp.item_code][2])
            new_give_drug_enc.dispensed_drug_name2 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage2 = drug_disp.take_qty
            new_give_drug_enc.dispensed_quantity2 = drug_disp.qty
          when 3
            new_give_drug_enc.pres_drug_name3 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.pres_dosage3 = drug_disp.take_qty
            new_give_drug_enc.pres_frequency3 = get_drug_frequency(drug_code[drug_disp.item_code][2])
            new_give_drug_enc.dispensed_drug_name3 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage3 = drug_disp.take_qty
            new_give_drug_enc.dispensed_quantity3 = drug_disp.qty
          when 4
            new_give_drug_enc.pres_drug_name4 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.pres_dosage4 = drug_disp.take_qty
            new_give_drug_enc.pres_frequency4 = get_drug_frequency(drug_code[drug_disp.item_code][2])
            new_give_drug_enc.dispensed_drug_name4 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage4 =  drug_disp.take_qty
            new_give_drug_enc.dispensed_quantity4 = drug_disp.qty
          when 5
            new_give_drug_enc.pres_drug_name5 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.pres_dosage5 = drug_disp.take_qty
            new_give_drug_enc.pres_frequency5 = get_drug_frequency(drug_code[drug_disp.item_code][2])
            new_give_drug_enc.dispensed_drug_name5 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage5 = drug_disp.take_qty
            new_give_drug_enc.dispensed_quantity5 = drug_disp.qty
        end
      drug_no += 1
      $encounter_id += 1
    end

    new_give_drug_enc.patient_id = patient_id
    new_give_drug_enc.old_enc_id = $encounter_id
    new_give_drug_enc.visit_encounter_id = create_visit_encounter(clinic_day, patient_id)
    new_give_drug_enc.voided = 0
    new_give_drug_enc.date_created = dispensation_records.first.cdate
    new_give_drug_enc.encounter_datetime = clinic_day
    new_give_drug_enc.creator = 1
    new_give_drug_enc.save
    $encounter_id += 1
  end


end

def create_outcome_encounter(t_rec, patient_id,enc_date)
  #by justin
  create_outcome_enc = PatientOutcome.new
  create_outcome_enc.outcome_id = $visit_encounter_hash["#{patient_id}#{enc_date}"].blank? ? create_visit_encounter(enc_date,patient_id) : $visit_encounter_hash["#{patient_id}#{enc_date}"]
  create_outcome_enc.visit_encounter_id =  $visit_encounter_hash["#{patient_id}#{enc_date}"].blank? ? create_visit_encounter(enc_date,patient_id) : $visit_encounter_hash["#{patient_id}#{enc_date}"] 
  create_outcome_enc.patient_id = patient_id
  create_outcome_enc.outcome_state = get_status(t_rec.OutcomeStatus)
  create_outcome_enc.outcome_date = t_rec.ClinicDay
  create_outcome_enc.save
end

def create_art_visit(record,patient,bart_patient)
  #by timothy
  new_art_visit  = ArtVisitEncounter.new

  new_art_visit.visit_encounter_id = create_visit_encounter(record.ClinicDay,bart_patient.id)
  new_art_visit.old_enc_id = $encounter_id
  new_art_visit.patient_id = bart_patient.patient_id
  new_art_visit.patient_pregnant = "Yes" if (record.pregnacy == "Y")
  new_art_visit.using_family_planning_method = "Yes" if (record.Depo == "Y" || record.Condom > 0)
  new_art_visit.family_planning_method_used = (record.Depo == "Y") ? "Depo Vera" : "Condom" if new_art_visit.using_family_planning_method == "Yes"
  new_art_visit.abdominal_pains = ""
  new_art_visit.anorexia = ""
  new_art_visit.cough = ""
  new_art_visit.diarrhoea = ""
  new_art_visit.fever = ""
  new_art_visit.jaundice = ""
  new_art_visit.leg_pain_numbness = ""
  new_art_visit.vomit = ""
  new_art_visit.weight_loss = ""
  new_art_visit.peripheral_neuropathy = ""
  new_art_visit.hepatitis = ""
  new_art_visit.anaemia = ""
  new_art_visit.lactic_acidosis = ""
  new_art_visit.lipodystrophy = ""
  new_art_visit.skin_rash = ""
  new_art_visit.other_symptoms = ""
  new_art_visit.drug_induced_Abdominal_pains = ""
  new_art_visit.drug_induced_anorexia = ""
  new_art_visit.drug_induced_diarrhoea = ""
  new_art_visit.drug_induced_jaundice = ""
  new_art_visit.drug_induced_leg_pain_numbness = ""
  new_art_visit.drug_induced_vomit = ""
  new_art_visit.drug_induced_peripheral_neuropathy = ""
  new_art_visit.drug_induced_hepatitis = ""
  new_art_visit.drug_induced_anaemia = ""
  new_art_visit.drug_induced_lactic_acidosis = ""
  new_art_visit.drug_induced_lipodystrophy = ""
  new_art_visit.drug_induced_skin_rash = ""
  new_art_visit.drug_induced_other_symptom = ""
  new_art_visit.tb_status = get_tb_status(record.Tb_status)
  new_art_visit.refer_to_clinician = ""
  new_art_visit.prescribe_arv = "Yes" if !record.OfThoseAlive.blank?

  last_disp = get_last_dispensations(record.ClinicDay, record.id)
  drug_no = 1

  (last_disp || []).each do |dispensation|
    case drug_no
      when 1

        new_art_visit.drug_name_brought_to_clinic1 = $drug_code[dispensation.item_code][1]
        new_art_visit.drug_quantity_brought_to_clinic1 = dispensation.leftqty
        new_art_visit.drug_left_at_home1 = 0

      when 2

        new_art_visit.drug_name_brought_to_clinic2 = $drug_code[dispensation.item_code][1]
        new_art_visit.drug_quantity_brought_to_clinic2 = dispensation.leftqty
        new_art_visit.drug_left_at_home2 = 0

      when 3

        new_art_visit.drug_name_brought_to_clinic3 = $drug_code[dispensation.item_code][1]
        new_art_visit.drug_quantity_brought_to_clinic3 = dispensation.leftqty
        new_art_visit.drug_left_at_home3 = 0

      when 4

        new_art_visit.drug_name_brought_to_clinic4 = $drug_code[dispensation.item_code][1]
        new_art_visit.drug_quantity_brought_to_clinic4 = dispensation.leftqty
        new_art_visit.drug_left_at_home4 = 0
    end
    drug_no += 1
  end

  new_art_visit.arv_regimen = record.OfThoseAlive
  new_art_visit.prescribe_cpt = ""
  new_art_visit.prescribe_ipt = ""
  new_art_visit.number_of_condoms_given = record.Condom
  new_art_visit.depo_provera_given = "Yes" if record.Depo == "Y"
  new_art_visit.continue_treatment_at_clinic = "Yes" if record.OutcomeStatus = "A"
  new_art_visit.continue_art = "Yes" if record.OutcomeStatus = "A"
  new_art_visit.voided = 0
  new_art_visit.encounter_datetime = record.ClinicDay
  new_art_visit.date_created = record.cdate
  new_art_visit.creator = 1
  new_art_visit.save
  $encounter_id += 1
end

def get_relationship(per)
  if per.guardianrelation == 'SPO'
    relationship = "Spouse/Partner"
  elsif per.guardianrelation == 'SIS'
    relationship = "Sibling"
  elsif per.guardianrelation == 'BRO'
    relationship = "Sibling"
  elsif per.guardianrelation == 'MTH'
    relationship = "Parent"
  elsif per.guardianrelation == 'FTH'
    relationship = "Parent"
  elsif per.guardianrelation == 'OTH'
    relationship = "Other"
  else
    relationship = "Other"
  end

  return relationship
end

def get_relation_gender(patient_gender, relationship)

  case relationship
    when 'SPO'
      if patient_gender == '1'
        gender = "F"
      else
        gender = "M"
      end
    when 'MTH'
        gender = "F"
    when 'FTH'
      gender = "M"
    when 'SIS'
      gender = "F"
    when 'BRO'
      gender = "M"
    else
      gender = "U"
  end
 return gender
end

def get_patient_height(record)
  #This method gets the hieght of a patient for a particulare visit otherwise it gets the last known height

  if record.Height != 0
    return record.Height.to_i
  else

    last_height = TesmartOpdReg.find(:last, :order => "ClinicDay asc",
                        :conditions => ["arv_no = ? AND Height != 0 AND ClinicDay <= ? ", record.arv_no,record.ClinicDay])
    if last_height.blank?
      return TesmartPatient.find( record.arv_no).Height rescue 0
    else
      return last_height.Height
    end

  end

end

def get_drug_frequency(frequency)
	case frequency
		when "TWICE A DAY (BD)"
		times = 2 
		when "IN THE EVENING (QPM)"
		times = 1 
		when "ONCE A DAY (od)"
		times = 1 
       end 
	return times
end	
def get_status(patient_state)
	 case  patient_state
	 when "A"
          state = "On ART"
	  when "D"
	  state = "Died"
	  when "TO" 
	  state = "Transfer Out(With Transfer Note)"
	  when "DF"
	   state = "On ART"
	  when "STOP"
	  state = "ART Stop"
	  else
	    state = "On ART"	  
         end 
   return state
end	

def get_location(h_code)
   return TesmartSite.find(h_code).h_name rescue "Unknown"
end	

def create_visit_encounter(encounter_date, patient)
  if $visit_encounter_hash["#{patient}#{encounter_date.to_date}"].blank?
    new_visit_enc = VisitEncounter.new
    new_visit_enc.patient_id = patient
    new_visit_enc.visit_date = encounter_date
    new_visit_enc.save
    $visit_encounter_hash["#{patient}#{encounter_date.to_date}"] = new_visit_enc.id
    return new_visit_enc.id
  else
    return $visit_encounter_hash["#{patient}#{encounter_date.to_date}"]
  end
end

def get_followup_status(t_patient, record)
  case t.patient.Pursue
    when "Y"
      return "Yes"

    when "N"
      return "No"

    else
      check = TesmartOpdReg.find(:all, :conditions => ["arv_no = ? AND ClinicDay > ?", t_patient.id, record.ClinicDay])
      if check.blank?
        return "No"
      else
        return "True"
      end
  end
end

def get_last_dispensations(clinic_date, patient_id)

  records = TesmartOpdTran.find_by_sql("SELECT e.* FROM opd_tran as e where e.arv_no = #{patient_id} AND
              ClinicDay = (SELECT MAX(ClinicDay) from opd_tran where arv_no = #{patient_id} AND DATE(ClinicDay) < DATE(#{clinic_date}))")

  return records
end

def get_tb_status(status)
  case status
    when "No"
      return "TB NOT suspected"
    when "Yes"
      return "TB suspected"
    when "Rx"
      return "Confirmed TB on treatment"
    when "NoRx"
      return "Confirmed TB NOT on treatment"
    else
      return "Unknown"
  end
end
start
