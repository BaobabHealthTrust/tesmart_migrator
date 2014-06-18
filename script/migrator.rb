$person_id = 2
$encounter_id = 1
$visit_encounter_hash = {}
$hospital_id = 214
$outcome_id = 1
$site = TesmartHospital.first.h_name
$drug_code = {"TDF3TC"=>[734,'Tenofovir Disoproxil Fumarate/Lamivudine 300mg/300',"IN THE EVENING",1,7928],
             "CPT"=>[297,'Cotrimoxazole 480',"TWICE A DAY (BD)", 1,916],
             "CO"=>[297,'Cotrimoxazole 480',"TWICE A DAY (BD)", 1,916],
             "CTX"=>[576,'Cotrimoxazole 960',"IN THE EVENING (QPM)",1,916],
             "ATV/r_A"=>[817,"atr/A 100/200mg","IN THE EVENING (QPM)",1,8384],
             "L3015_A"=>[738,'Stavudine 30 Lamivudine 150',"ONCE A DAY (od)",1,2833],
             "T3060_A"=>[613,'Stavudine 30 Lamivudine 150 Nevirapine 200',"TWICE A DAY (BD)",1,792],
             "AZT3TCN_A"=>[731,'Zidovudine 300 Lamivudine 150 Nevirapine 200',"TWICE A DAY (BD)",3,1610],
             "AZT3TCN_P"=>[732,'Zidovudine 60 Lamivudine 30 Nevirapine 50',"TWICE A DAY (BD)",1,1610],
             "TDF3TCEFV"=>[735,'Tenofavir 300 Lamivudine 300 and Efavirenz 600',"IN THE EVENING (QPM)",1,2985],
             "L3015_P"=>[72,'Stavudine 6 Lamivudine 30 Nevirapine 50',"TWICE A DAY(BD)",1,2985],
             "AZT3TCN_P"=>[732,'Zidovudine 60 Lamivudine 30 Nevirapine 50',"TWICE A DAY (BD)",1,1610],
             "ABC3TC"=>[733,'Abacavir 60 and Lamivudine 30',"TWICE A DAY (BD)",4,7927],
             "AZT3TC_A"=>[731,"Zidovudine 300 Lamivudine 150 Nevirapine 200","TWICE A DAY (BD)",1,1610],
             "AZT3TC_P"=>[732,"Zidovudine 60 Lamivudine 30 Nevirapine 50","TWICE A DAY (BD)",3,1610],
             "LPVr_P"=>[74,"Lopinavir 100 Ritonavir 25","TWICE A DAY (BD)",2,794],
             "LPVr_A"=>[73,"Lopinavir 200 Ritonavir 50","TWICE A DAY (BD)",2,794],
             "L3060_P"=>[737,"Stavudine 6 Lamivudine 30","TWICE A DAY (BD)",3,2833],
             "L3060_A"=>[738,"Stavudine 30 Lamivudine 150","ONCE A DAY (od)",1,2833],
             "T3060_P"=>[72,"Stavudine Lamivudine Nevirapine (Triomune Baby)","IN THE EVENING (QPM)",1,792],
             "T3015_A"=>[613,"Stavudine 30 Lamivudine 150 Nevirapine 200","IN THE EVENING (QPM)",1,792],
             "T3015_P"=>[737,"Stavudine 6 Lamivudine 30 Nevirapine 50","IN THE EVENING (QPM)",1,2833],
             "EFV_A"=>[11,"Efavirenz 600","TWICE A DAY (BD)",1,633],
             "EFV_P"=>[30,"Efavirenz 200","TWICE A DAY (BD)",1,633],
             "NVP"=>[22,"Nevirapine 200","TWICE A DAY (BD)",1,631],
             "IPT"=>[24,"INH or H (Isoniazid 100mg tablet)","IN THE EVENING (QPM)",1,656] }


def start
  patients = TesmartPatient.find(:all, :order=>"arv_no",:limit=>300,:offset=>2000)
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

      create_hiv_staging_encounter(patient,staging,patient_id) unless staging.blank?
      create_first_visit_encounter(patient,patient_id)
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
  if t_patient.Sex.to_i == 1
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
  new_patient.date_created = t_patient.FirstLineARV
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
  new_guardian.date_created = t_patient.FirstLineARV
  new_guardian.save

  patient = Patient.find(patient_id)
  patient.guardian_id = new_guardian_patient.patient_id
  patient.save
end


def process_patient_records(patient, patient_id)
  $outcome_encounter = 1
  $p_outcome_id = 1
  visit_records = TesmartOpdReg.find(:all, :conditions => ["arv_no = ? ", patient.id] )
  bart_patient = Patient.find(patient_id)
  (visit_records || []).each do |record|
    height = get_patient_height(record)
    create_outcome_encounter(record,patient_id)
    create_outcome(record, patient_id,record.ClinicDay)
    create_art_visit(record,patient,bart_patient)
    create_give_drugs_encounter(record.ClinicDay, patient, patient_id,record.pillrunoutdate, record.OfThoseAlive)
    create_vitals_encounter(record.Weight,height, patient_id, record.ClinicDay, record.ClinicDay)
    create_hiv_reception_encounter(bart_patient,record.ARVGiven,record.ClinicDay, record.ClinicDay)
  end

  end


def create_outcome_encounter(t_rec,patient_id)
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
     outcome.location = $site
     outcome.voided = 0
     outcome.encounter_datetime = t_rec.ClinicDay
     outcome.date_created = t_rec.ClinicDay
     outcome.creator = 1
     outcome.save
     $encounter_id += 1

end

def create_first_visit_encounter(t_patient, patient_id)

  new_first_visit_enc = FirstVisitEncounter.new
  new_first_visit_enc.agrees_to_follow_up = get_followup_status(t_patient, t_patient.DateOfBegin)
  new_first_visit_enc.date_of_hiv_pos_test = t_patient.HIV_Positive_Date
  new_first_visit_enc.date_of_art_initiation = t_patient.FirstLineARV

  if t_patient.HIV_Positive_Place.blank?
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
    new_first_visit_enc.last_arv_regimen = t_patient.Last_arvDrug.blank? ? "Unknown" : t_patient.Last_arvDrug
    new_first_visit_enc.date_last_arv_taken =  t_patient.Last_arvDate unless (t_patient.Last_arvDate.blank? || t_patient.Last_arvDate.to_date == "1899-12-30".to_date)
  end

  new_first_visit_enc.location_of_art_initiation = get_location(t_patient.FirstLineARVsite.blank? ? $hospital_id : t_patient.FirstLineARVsite)
	new_first_visit_enc.weight = t_patient.Weight
  if (!t_patient.Height.blank? && t_patient.Height > 0)
    new_first_visit_enc.height = t_patient.Height
    bmi = (t_patient.Weight.to_f/(t_patient.Height.to_f*t_patient.Height.to_f)*10000) rescue nil
    new_first_visit_enc.bmi = bmi.nan? ? nil : bmi
  end
  new_first_visit_enc.patient_id = patient_id
  new_first_visit_enc.old_enc_id = $encounter_id
  new_first_visit_enc.visit_encounter_id = create_visit_encounter(t_patient.DateOfBegin,patient_id)
  new_first_visit_enc.voided = 0
  new_first_visit_enc.location = $site
  new_first_visit_enc.date_created = t_patient.FirstLineARV
  new_first_visit_enc.encounter_datetime = t_patient.DateOfBegin
  new_first_visit_enc.creator = 1
  new_first_visit_enc.save
  $encounter_id += 1
end


def create_hiv_staging_encounter(t_patient, staging, patient_id)
 #by temwa
  new_staging = HivStagingEncounter.new
  new_staging.patient_id = patient_id

  new_staging.cd4_count = t_patient.InitCD4count
  new_staging.date_of_cd4_count = t_patient.InitCD4date.blank? ? t_patient.DateOfBegin : t_patient.InitCD4date

  age = t_patient.age rescue 0
#from Stage table in TESMART
#Stage 1 conditions
  new_staging.patient_pregnant = decode_staging_variable(staging.a3)
  new_staging.patient_breast_feeding = decode_staging_variable(staging.a4)
  new_staging.asymptomatic = decode_staging_variable(staging.a1)
  new_staging.persistent_generalized_lymphadenopathy = decode_staging_variable(staging.a2)
 # new_staging.unspecified_stage_1_cond = Null

#stage 2 conditions
  new_staging.molluscumm_contagiosum = decode_staging_variable(staging.b54)
  new_staging.wart_virus_infection_extensive = decode_staging_variable(staging.b53)
  new_staging.oral_ulcerations_recurrent = decode_staging_variable(staging.b55)
  new_staging.parotid_enlargement_persistent_unexplained = decode_staging_variable(staging.b56)
  new_staging.lineal_gingival_erythema = decode_staging_variable(staging.b57)
  new_staging.herpes_zoster = decode_staging_variable(staging.b5867)
  new_staging.respiratory_tract_infections_recurrent = decode_staging_variable(staging.b5968)
  #new_staging.unspecified_stage2_condition= Null

  new_staging.angular_chelitis = decode_staging_variable(staging.b2)
  new_staging.papular_prurtic_eruptions = decode_staging_variable(staging.b6169)
  new_staging.hepatosplenomegaly_unexplained = decode_staging_variable(staging.b51)
  
#  if !b1.blank?
 # new_staging.unspecified_stage2_condition = staging.c100
  #new_staging.unspecified_stage2_condition = Null

#stage 3 conditions
  new_staging.oral_hairy_leukoplakia = decode_staging_variable(staging.c2)
  new_staging.severe_weight_loss = decode_staging_variable(staging.c3)
  new_staging.fever_persistent_unexplained = decode_staging_variable(staging.c5)
  new_staging.extrapulmonary_tuberculosis= decode_staging_variable(staging.c6)
  new_staging.pulmonary_tuberculosis_last_2_years = decode_staging_variable(staging.c7)
  new_staging.severe_bacterial_infection = decode_staging_variable(staging.c8)
  new_staging.bacterial_pnuemonia = decode_staging_variable(staging.c53)
  new_staging.symptomatic_lymphoid_interstitial_pnuemonitis = decode_staging_variable(staging.c54)
  new_staging.chronic_hiv_assoc_lung_disease = decode_staging_variable(staging.c55)
  new_staging.aneamia = decode_staging_variable(staging.c10_1)
  new_staging.neutropaenia = decode_staging_variable(staging.c10_2)
  new_staging.thrombocytopaenia_chronic = decode_staging_variable(staging.c10_3)
  new_staging.diarhoea = decode_staging_variable(staging.c4)
  new_staging.oral_candidiasis = decode_staging_variable(staging.c1)
  new_staging.acute_necrotizing_ulcerative_gingivitis = decode_staging_variable(staging.c9)
  new_staging.lymph_node_tuberculosis = decode_staging_variable(staging.c52)

#  if !c100.blank?
#  new_staging.unspecified_stage3_conditions = staging.c100
 
  #new_staging.unspecified_stage3_conditions = Null

#stage 4 conditions
  new_staging.toxoplasmosis_of_brain = decode_staging_variable(staging.d3)
  new_staging.cryptococcal_meningitis = decode_staging_variable(staging.d6)
  new_staging.progressive_multifocal_leukoencephalopathy = decode_staging_variable(staging.d9)
  new_staging.disseminated_mycosis = decode_staging_variable(staging.d10)
  new_staging.candidiasis_of_oesophagus = decode_staging_variable(staging.d11)
  new_staging.extrapulmonary_tuberculosis = decode_staging_variable(staging.d14)
  new_staging.cerebral_non_hodgkin_lymphoma = decode_staging_variable(staging.d15)
  new_staging.kaposis = decode_staging_variable(staging.d16)
  new_staging.hiv_encephalopathy = decode_staging_variable(staging.d17)
  new_staging.bacterial_infections_severe_recurrent = decode_staging_variable(staging.d5)
  new_staging.pnuemocystis_pnuemonia = decode_staging_variable(staging.d2)
  new_staging.disseminated_non_tuberculosis_mycobactierial_infection = decode_staging_variable(staging.d12)
  new_staging.cryptosporidiosis = decode_staging_variable(staging.d4)
  new_staging.isosporiasis = decode_staging_variable(staging.d4_1)
  new_staging.symptomatic_hiv_asscoiated_nephropathy = decode_staging_variable(staging.dn1)
  new_staging.chronic_herpes_simplex_infection = decode_staging_variable(staging.d8)
  new_staging.cytomegalovirus_infection = decode_staging_variable(staging.d7)
  new_staging.toxoplasomis_of_the_brain_1month  = decode_staging_variable(staging.d3)
  new_staging.recto_vaginal_fitsula = decode_staging_variable(staging.dn2)

 # if !staging.d1.blank?
  new_staging.hiv_wasting_syndrome = decode_staging_variable(staging.d1)
  new_staging.reason_for_starting_art = get_reason_for_starting(new_staging, staging.staging,age,staging.clinicday )

  new_staging.who_stage = code_stage(staging.staging, age)
  new_staging.old_enc_id = $encounter_id
  new_staging.location = $site
  new_staging.creator = 1
  new_staging.voided = 0
  new_staging.encounter_datetime = staging.clinicday
  new_staging.date_created = staging.clinicday
  new_staging.visit_encounter_id = create_visit_encounter(staging.clinicday, patient_id)
  new_staging.save
  $encounter_id +=1
end
#end

def create_hiv_reception_encounter(patient,present,date_created, enc_date)
  new_recp_encounter = HivReceptionEncounter.new

  if present == "B"
    new_recp_encounter.guardian = patient.guardian.relative_id rescue nil
    new_recp_encounter.guardian_present = "Yes"
    new_recp_encounter.patient_present = "Yes"
  elsif present == "G"
    new_recp_encounter.guardian = patient.guardian.relative_id rescue nil
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
  new_recp_encounter.location = $site
  new_recp_encounter.voided = 0
  new_recp_encounter.save

  $encounter_id += 1
end

def create_vitals_encounter(weight, height, patient_id, cdate, enc_date)

  new_vitals_enc = VitalsEncounter.new
  new_vitals_enc.patient_id = patient_id
  new_vitals_enc.weight = weight
  unless ((height == 0) || (height.blank?))
    new_vitals_enc.height = height
    new_vitals_enc.bmi = (weight.to_f/(height.to_f*height.to_f)*10000) rescue nil
  end
  new_vitals_enc.visit_encounter_id = create_visit_encounter(enc_date, patient_id)
  new_vitals_enc.old_enc_id = $encounter_id
  new_vitals_enc.voided = 0
  new_vitals_enc.date_created = cdate
  new_vitals_enc.encounter_datetime = enc_date
  new_vitals_enc.creator = 1
  new_vitals_enc.location = $site
  new_vitals_enc.save
  $encounter_id += 1

end

def create_give_drugs_encounter(clinic_day, t_patient, patient_id,appointment_date, regimen)
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
            new_give_drug_enc.pres_dosage1 = get_drug_frequency($drug_code[drug_disp.item_code][2],$drug_code[drug_disp.item_code][3])
            new_give_drug_enc.pres_frequency1 = $drug_code[drug_disp.item_code][2]
            new_give_drug_enc.dispensed_drug_name1 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage1 = get_drug_frequency($drug_code[drug_disp.item_code][2],drug_disp.take_qty)
            new_give_drug_enc.dispensed_quantity1 = drug_disp.qty
          when 2
            new_give_drug_enc.pres_drug_name2 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.pres_dosage2 = get_drug_frequency($drug_code[drug_disp.item_code][2],$drug_code[drug_disp.item_code][3])
            new_give_drug_enc.pres_frequency2 = $drug_code[drug_disp.item_code][2]
            new_give_drug_enc.dispensed_drug_name2 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage2 = get_drug_frequency($drug_code[drug_disp.item_code][2],drug_disp.take_qty)
            new_give_drug_enc.dispensed_quantity2 = drug_disp.qty
          when 3
            new_give_drug_enc.pres_drug_name3 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.pres_dosage3 = get_drug_frequency($drug_code[drug_disp.item_code][2],$drug_code[drug_disp.item_code][3])
            new_give_drug_enc.pres_frequency3 = $drug_code[drug_disp.item_code][2]
            new_give_drug_enc.dispensed_drug_name3 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage3 = get_drug_frequency($drug_code[drug_disp.item_code][2],drug_disp.take_qty)
            new_give_drug_enc.dispensed_quantity3 = drug_disp.qty
          when 4
            new_give_drug_enc.pres_drug_name4 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.pres_dosage4 = get_drug_frequency($drug_code[drug_disp.item_code][2],drug_disp.take_qty)
            new_give_drug_enc.pres_frequency4 = $drug_code[drug_disp.item_code][2]
            new_give_drug_enc.dispensed_drug_name4 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage4 =  get_drug_frequency($drug_code[drug_disp.item_code][2],drug_disp.take_qty)
            new_give_drug_enc.dispensed_quantity4 = drug_disp.qty
          when 5
            new_give_drug_enc.pres_drug_name5 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.pres_dosage5 = get_drug_frequency($drug_code[drug_disp.item_code][2],$drug_code[drug_disp.item_code][3])
            new_give_drug_enc.pres_frequency5 = $drug_code[drug_disp.item_code][2]
            new_give_drug_enc.dispensed_drug_name5 = $drug_code[drug_disp.item_code][1]
            new_give_drug_enc.dispensed_dosage5 = get_drug_frequency($drug_code[drug_disp.item_code][2],drug_disp.take_qty)
            new_give_drug_enc.dispensed_quantity5 = drug_disp.qty
        end
      drug_no += 1
    end

    new_give_drug_enc.patient_id = patient_id
    new_give_drug_enc.appointment_date = appointment_date unless appointment_date.blank?
    new_give_drug_enc.regimen_category = regimen
    new_give_drug_enc.old_enc_id = $encounter_id
    new_give_drug_enc.visit_encounter_id = create_visit_encounter(clinic_day, patient_id)
    new_give_drug_enc.voided = 0
    new_give_drug_enc.location = $site
    new_give_drug_enc.date_created = dispensation_records.first.cdate
    new_give_drug_enc.encounter_datetime = clinic_day
    new_give_drug_enc.creator = 1
    new_give_drug_enc.save
    $encounter_id += 1
  end


end

def create_outcome(t_rec, patient_id,enc_date)
  #by justin
  new_outcome = PatientOutcome.new
  new_outcome.outcome_id = $outcome_id
  new_outcome.visit_encounter_id =  create_visit_encounter(t_rec.ClinicDay, patient_id)
  new_outcome.patient_id = patient_id
  new_outcome.outcome_state = get_status(t_rec.OutcomeStatus)
  new_outcome.outcome_date = t_rec.ClinicDay
  new_outcome.save
  $outcome_id += 1
end

def create_art_visit(record,patient,bart_patient)
  #by timothy
  new_art_visit  = ArtVisitEncounter.new

  new_art_visit.visit_encounter_id = create_visit_encounter(record.ClinicDay,bart_patient.id)
  new_art_visit.old_enc_id = $encounter_id
  new_art_visit.patient_id = bart_patient.patient_id
  new_art_visit.patient_pregnant = "Yes" if (record.pregnancy == "Y")
  new_art_visit.using_family_planning_method = "Yes" if (record.Depo == "Y" || record.Condom > 0)
  new_art_visit.family_planning_method_used = (record.Depo == "Y") ? "Depo Vera" : "Condom" if new_art_visit.using_family_planning_method == "Yes"

  if !record.caseM.blank?
    if record.caseM_desc.blank?
      new_art_visit.other_symptoms = "Yes"
    else
      new_art_visit.abdominal_pains = "Yes" if record.caseM_desc.upcase.match(/ABDOMINAL PAIN/i)
      new_art_visit.cough = "Yes" if record.caseM_desc.upcase.match(/COUGH/i)
      new_art_visit.diarrhoea = "Yes" if record.caseM_desc.upcase.match(/DIARRHOEA/i)
      new_art_visit.fever = "Yes" if record.caseM_desc.upcase.match(/FEVER/i)
      new_art_visit.jaundice = "Yes" if record.caseM_desc.upcase.match(/YELLOW/i)
      new_art_visit.leg_pain_numbness = "Yes" if record.caseM_desc.upcase.match(/LEG PAIN/i)
      new_art_visit.leg_pain_numbness = "Yes" if record.caseM_desc.upcase.match(/NUMBNESS/i)
      new_art_visit.vomit = "Yes" if record.caseM_desc.upcase.match(/VOMIT/i)
      new_art_visit.weight_loss = "Yes" if record.caseM_desc.upcase.match(/MALNUTRITION/i)
=begin
      No matching options for these
      new_art_visit.peripheral_neuropathy = ""
      new_art_visit.hepatitis = ""
      new_art_visit.anaemia = ""
      new_art_visit.anorexia = ""
      new_art_visit.lactic_acidosis = ""
=end
      new_art_visit.lipodystrophy = "Yes" if record.caseM_desc.upcase.match(/BODY SHAPE/i)
      new_art_visit.skin_rash = "Yes" if record.caseM_desc.upcase.match(/RASH/i)
      new_art_visit.other_symptoms = "Yes" if record.caseM_desc.upcase.match(/OTHER/i)
    end
  end



  if !record.SideEffects.blank?
    case record.SideEffects

      when "OT"
        new_art_visit.drug_induced_other_symptom = "Yes"
      when "PN"
        new_art_visit.drug_induced_peripheral_neuropathy = "Yes"
      when "SK"
        new_art_visit.drug_induced_skin_rash = "Yes"
      when "Y"
          if record.side_desc.blank?
            new_art_visit.drug_induced_other_symptom = "Yes"
          else
            new_art_visit.drug_induced_skin_rash = "Yes" if record.side_desc.upcase.match(/SK/i)
            new_art_visit.drug_induced_peripheral_neuropathy = "Yes" if record.side_desc.upcase.match(/PN/i)
            new_art_visit.drug_induced_peripheral_neuropathy = "Yes" if record.side_desc.upcase.match(/PERIPHERAL NEUROPATHY/i)
            new_art_visit.drug_induced_other_symptom = "Yes" if record.side_desc.upcase.match(/OTHER/i)
            new_art_visit.drug_induced_lipodystrophy = "Yes" if record.side_desc.upcase.match(/LD/i)
            new_art_visit.drug_induced_lipodystrophy = "Yes" if record.side_desc.upcase.match(/LIPODYSTROPHY/i)
            new_art_visit.drug_induced_lipodystrophy = "Yes" if record.side_desc.upcase.match(/LIP/i)
            new_art_visit.drug_induced_anaemia = "Yes" if record.side_desc.upcase.match(/ANAEMIA/i)
            new_art_visit.drug_induced_lactic_acidosis = "Yes" if record.side_desc.upcase.match(/LACTIC ACIDOSIS/i)
            new_art_visit.drug_induced_hepatitis = "Yes" if record.side_desc.upcase.match(/HP/i)
            new_art_visit.drug_induced_hepatitis = "Yes" if record.side_desc.upcase.match(/HEPATITIS/i)
            new_art_visit.drug_induced_Abdominal_pains = "Yes" if record.side_desc.upcase.match(/ABDOMINAL/i)
            new_art_visit.drug_induced_anorexia = "Yes" if record.side_desc.upcase.match(/ANOREXIA/i)
            new_art_visit.drug_induced_diarrhoea = "Yes" if record.side_desc.upcase.match(/DIARRHOEA/i)
            new_art_visit.drug_induced_jaundice = "Yes" if record.side_desc.upcase.match(/JAUNDICE/i)
            new_art_visit.drug_induced_leg_pain_numbness = "Yes" if record.side_desc.upcase.match(/NUMBNESS/i)
            new_art_visit.drug_induced_vomit = "Yes" if record.side_desc.upcase.match(/VOMIT/i)
          end
      when "AN"
        new_art_visit.drug_induced_anorexia = "Yes"
    end
  end

  last_disp = get_last_dispensations(record.ClinicDay, record.arv_no)
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
    new_art_visit.prescribe_cpt = "Yes" if $drug_code[dispensation.item_code][1].match(/Cotrimoxazole/i) rescue false
    new_art_visit.prescribe_ipt = "Yes" if $drug_code[dispensation.item_code][1].match(/Isoniazid/i) rescue false
  end

  new_art_visit.tb_status = get_tb_status(record.Tb_status)
  new_art_visit.prescribe_arv = "Yes" if !record.OfThoseAlive.blank?
  new_art_visit.arv_regimen = record.OfThoseAlive if !record.OfThoseAlive.blank?
  new_art_visit.number_of_condoms_given = record.Condom
  new_art_visit.depo_provera_given = "Yes" if record.Depo == "Y"
  new_art_visit.continue_treatment_at_clinic = "Yes" if record.OutcomeStatus =="A"
  new_art_visit.continue_art = "Yes" if record.OutcomeStatus == "A"
  new_art_visit.voided = 0
  new_art_visit.encounter_datetime = record.ClinicDay
  new_art_visit.date_created = record.cdate
  new_art_visit.location = $site
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

def get_drug_frequency(frequency, dose)
	case frequency
		when "TWICE A DAY (BD)"
		times = "#{dose}-#{dose}"
		when "IN THE EVENING (QPM)"
		times = dose
		when "ONCE A DAY (od)"
		times = dose
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

def get_followup_status(t_patient, cdate)
  case t_patient.Pursue
    when "Y"
      return "Yes"

    when "N"
      return "No"

    else
      check = TesmartOpdReg.find(:all, :conditions => ["arv_no = ? AND ClinicDay > ?", t_patient.id, cdate])
      if check.blank?
        return "No"
      else
        return "True"
      end
  end
end

def get_last_dispensations(clinic_date, patient_id)

  records = TesmartOpdTran.find_by_sql("SELECT e.* FROM opd_tran as e where e.arv_no = #{patient_id} AND
              ClinicDay = (SELECT MAX(ClinicDay) from opd_tran where arv_no = #{patient_id} AND DATE(ClinicDay) < DATE('#{clinic_date}'))")

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

def decode_staging_variable(ans)

  if !ans.blank?
    case ans
      when "Y"
        return "Yes"
      when "N"
        return "No"
    end

  end

  return nil
end

def code_stage(stage, age)

  case stage
    when "1"
      if age < 14
        return "WHO stage I peds"
      else
        return "WHO stage I adult"
      end
    when "2"
      if age < 14
        return "WHO stage II peds"
      else
        return "WHO stage II adult"
      end
    when "3"
      if age < 14
        return "WHO stage III peds"
      else
        return "WHO stage III adult"
      end
    when "4"
      if age < 14
        return "WHO stage IV peds"
      else
        return "WHO stage IV adult"
      end
    when "P"
      return "WHO stage I peds"
  end
end

def get_reason_for_starting(staging_enc, who_stage, age, enc_date)

  cd4_count = staging_enc.cd4_count
  stage = who_stage
  adult_or_peds = age < 14 ? "peds" : "adult"

  age_in_months = age * 12

  low_cd4_count_350 = false
  cd4_count_less_than_750 = false
  low_cd4_count_250 = false

  unless cd4_count.blank?
    if cd4_count <= 250 # and (staging_enc.date_of_cd4_count < '2011-07-01'.to_date)
      low_cd4_count_250 = true
    elsif cd4_count <= 350 #and (staging_enc.date_of_cd4_count >= '2011-07-01'.to_date)
      low_cd4_count_350 = true
    elsif cd4_count <= 750
      cd4_count_less_than_750 = true
    end

  end

  if stage == "3" || stage == "4"

    return "WHO stage #{stage} #{adult_or_peds}"

  elsif low_cd4_count_350 and stage.to_i < 3 #and enc_date  >= '2011-07-01'.to_date

    return "CD4 count < 350"
 
  elsif low_cd4_count_250 and stage.to_i < 3

    return "CD4 count < 250"

  elsif staging_enc.patient_pregnant = "Yes"
    return "Patient Pregnant"
  elsif staging_enc.patient_breast_feeding = "Yes"
    return "Breastfeeding"
  elsif adult_or_peds == "peds"

    if age_in_months >= 12 and age_in_months < 24
      return "Child HIV positive"
    elsif (age_in_months >= 24 and age_in_months < 56) and cd4_count_less_than_750
      return "CD4 count < 750"
    else
      return "Unknown"
    end

  else

    return "Unknown"

  end


end
start
