$person_id = 2
@site = 'RU'
def start
  patients = TesmartPatient.all
  count = patients.length
  @traditional_authorities =  TesmartLookup.load_traditional_authority
  @traditionalauthoritydata = Hash.new("unknown")
   @traditional_authorities.each do |ta|
     @traditionalauthoritydata[ta.item_code] = ta.code_desc
    end
  @occupation = TesmartLookup.load_occupation_data
  @occupationdata = Hash.new("Missing")
  @occupation.each do |occ|
	@occupationdata[occ.item_code] = occ.code_desc
end
 @villages = TesmartLookup.load_villages
 @villagedata = Hash.new("unknown")
 @villages.each do |vil|
            @villagedata[vil.item_code] = vil.code_desc
end
  puts "Patients to be migrated #{count}"
  (patients || []).each do |patient|
    next if patient.id == 0
    puts "Working on patient id #{patient.id}, #{count} patients left"
    create_patient(patient)
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
  new_patient.save

  $person_id +=1

  create_guardian(t_patient, new_patient.id)

end

def create_guardian(t_patient, patient_id)

  guardian_names = t_patient.GuardianName.split(" ")
  gender = get_relation_gender(t_patient.Sex, t_patient.guardianrelation)
  new_guardian_patient = Patient.new
  new_guardian_patient.patient_id = $person_id
  new_guardian_patient.given_name = guardian_names.first
  new_guardian_patient.family_name = guardian_names.last
  new_guardian_patient.gender = gender
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

end

def create_visit_encounter

end

def create_outcome

end

def create_first_visit_encounter

end

def create_hiv_staging_encounter

end

def create_hiv_reception_encounter

  new_recp_encounter = HivReceptionEncounter.new
  new_recp_encounter.guardian = Patient.gaurdian
  new_recp_encounter.save

end

def create_vitals_encounter

  new_vitals_enc = VitalsEncounter.new
  new_vitals_enc.patient_id = patient_id
  new_vitals_enc.weight = weight
  new_vitals_enc.height = height
  new_vitals_enc.bmi = (weight.to_f/(height.to_f*height.to_f)*10000) rescue nil
  new_vitals_enc.save

end

def create_give_drugs_encounter

end

def create_outcome_encounter

end

def create_art_visit

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
      if patient_gender == 1
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

start