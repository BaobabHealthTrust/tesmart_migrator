$person_id = 2
$hospital_id = 214
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

      create_hiv_staging_encounter(staging,patient,patient_id)
      create_first_visit_encounter
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
  new_patient.art_number = "#{@site_code}" + "-" + "ARV" + "-" + "#{t_patient.arv_no}"
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

  visit_records = TesmartOpdReg.find(:all, :conditions => ["arv_no = ? ", patient.id] )
  dispensation_records = TesmartOpdTran.find(:all, :conditions => ["arv_no = ? ", patient.id] )
  (visit_records || []).each do |record|
    height = get_patient_height(record)
    create_vitals_encounter(record.Weight,height, patient_id)
    create_outcome(record,patient_id)
  end

  (dispensation_records || []).each do |disp_record|
    create_give_drugs_encounter(disp_record, patient_id)
  end

end

def create_outcome(t_rec, patient_id)
  #by justin
     outcome = OutcomeEncounter.new
     outcome.old_enc_id = $outcome_encounter
     outcome.patient_id =  patient_id
     outcome.state = get_status(t_rec.OutcomeStatus )
     outcome.outcome_date =  t_rec.ClinicDay
     if !(t_rec.TransferOutTO.blank?)
     outcome.transfer_out_location = get_location(t_rec.TransferOutTO)
     end
     outcome.location = $hospital_id
     outcome.voided = 0
     outcome.encounter_date_time = t_rec.ClinicDay
     outcome.date_created = t_rec.mdate
     outcome.creator = 1
     outcome.save
     $outcome_encounter += 1
end
def create_first_visit_encounter
  #by timothy
end

def create_hiv_staging_encounter(t_stage, t_patient, patient_id)
  #by temwa
  new_staging = HivStagingEncounter.new
  new_staging.patient_id = patient_id
#from patiet table in TESMART
  new_staging.cd4_count = t_patient.initCD4Count
  new_staging.date_of_cd4_count = t_patient.initCD4Date #check!!!

#from Stage table in TESMART
#Stage 1 conditions
  new_staging.patient_pregnant = t_stage.a3
  new_staging.patient_breast_feeding = t_stage.a4
  new_staging.asymptomatic = t_stage.a1
  new_staging.persistent_generalized_lymphadenopathy = t_stage.a2
 # new_staging.unspecified_stage_1_cond = Null

#stage 2 conditions
  new_staging.molluscum_contagiosum = t_stage.b54
  new_staging.wart_virus_infection_extensive = t_stage.b53
  new_staging.oral_ulcerations_recurrent = t_stage.b55
  new_staging.parotid_enlargement_persistent_unexplained = t_stage.b56
  new_staging.lineal_gingival_erythema = t_stage.b57
  new_staging.herpes_zoster = t_stage.b5867
  new_staging.respiratory_tract_infection_recurrent = t_stage.b5968
  new_staging.angular_chelitis = t_stage.b2
  new_staging.papular_prutic_eruptions = t_stage.b6169
  new_staging.hepatosplenomegaly_unexplained = t_stage.b51
  
  if !b1.blank?
  new_staging.unspecified_stage2_condition = t_stage.c100
  #new_staging.unspecified_stage2_condition = Null

#stage 3 conditions
  new_staging.oral_hairy_leukoplakia =t_stage.c2
  new_staging.severe_weight_loss = t_stage.c3
  new_staging.fever_persistent_unexplained = t_stage.c5
  new_staging.pulmonary_tubercuosis = t_stage.c6
  new_staging.pulmonary_tuberculosis_last_2_years = t_stage.c7
  new_staging.severe_bacterial_infection = t_stage.c8
  new_staging.bacterial_pnuemonia = t_stage.c53
  new_staging.symptomatic_lymphoid_interstitial_pnuemonitis = t_stage.c54
  new_staging.chronic_hiv_assoc_lung_disease = t_stage.c55
  new_staging.aneamia = t_stage.c10_1
  new_staging.neutropaenia = t_stage.c10_2
  new_staging.thrombocytopaenia_chronic = t_stage.c10_3
  new_staging.diarhoea = t_stage.c4
  new_staging.oral_candidiasis = t_stage.c1
  new_staging.acute_necrotizing_ulcerative_gingivitis = t_stage.c9
  new_staging.lymph_node_tuberculosis = t_stage.c52

  if !c100.blank?
  new_staging.unspecified_stage3_conditions = t_stage.c100
 
  #new_staging.unspecified_stage3_conditions = Null

#stage 4 conditions
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
  #new_staging.unspecified_stage_4_condition = Null
  new_staging.who_stage = t_stage.staging
  new_staging.date_created  = t_stage.cdate

  new_staging.save	
end

def create_hiv_reception_encounter

  new_recp_encounter = HivReceptionEncounter.new
  new_recp_encounter.guardian = Patient.gaurdian
  new_recp_encounter.save

end

def create_vitals_encounter(weight, height, patient_id)

  new_vitals_enc = VitalsEncounter.new
  new_vitals_enc.patient_id = patient_id
  new_vitals_enc.weight = weight
  new_vitals_enc.height = height
  new_vitals_enc.bmi = (weight.to_f/(height.to_f*height.to_f)*10000) rescue nil
  new_vitals_enc.save

end

def create_give_drugs_encounter
  #by justin
end

def create_outcome_encounter

  #by justin
end

def create_art_visit
  #by timothy
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
  #improve method
  return record.Height
end

def get_status(patient_state)
	 case  patient_state
	 when "A"
          state = "On ART"
	  when "D"
	  state = "Died"
	  when "TO" 
	  state = "Transfered out  (with a letter)"
	  when "DF"
	   state = "On ART"
	  when "STOP"
	  state = "Stopped"
	  else
	    state = "On ART"	  
         end 
   return state
end	

def get_location(h_code)
	 locationdata = Hash.new("Unknown")
        @sites = Location.find(:all)
        @sites.each do |loc|
	 locationdata[loc.h_value] = loc.h_name   
      end
   hospital_name = locationdata[h_code]
   return hospital_name
end	
