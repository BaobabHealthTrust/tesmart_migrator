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
	t_patient.TA = "0xx"
  end  
  new_patient.traditional_authority = @traditionalauthoritydata[t_patient.TA]
  #Add more  
  if t_patient.Village.blank?
	t_patient.Village = "0xx"
  end
  new_patient.current_address = @villagedata[t_patient.Village]
  new_patient.cellphone_number = t_patient.CellPhone
  new_patient.occupation = @occupationdata[t_patient.Occupation]
  new_patient.guardian_id = ''
  new_patient.art_number = "#{@site_code}" + "-" + "ARV" + "-" + "#{per.arv_no}"
  new_patient.voided = 0
  new_patient.creator = 1
  new_patient.date_created = t_patient.cdate
  new_patient.home_phone_number = t_patient.HomePhone
  new_patient.dob_estimated = 0
  new_patient.landmark = t_patient.Address
  new_patient.save

  $person_id +=1

  #create_guardian(t_patient, new_patient.id)

end

def create_guardian(t_patient, patient_id)
  new_guardian_patient = Patient.new
  new_guardian_patient.patient_id = $person_id
  #Add more attributes
  new_guardian_patient.save
  
  new_gaurdian = Guardian.new
  new_guardian.patient_id = patient_id
  new_guardian.relative_id = new_guardian_patient.patient_id
  new_guardian.relationship = get_relationship(t_patient)
  #Add more attributes
  new_guardian.save
  $person_id +=1
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

end

def create_vitals_encounter

end

def create_give_drugs_encounter

end

def create_outcome_encounter

end

def create_art_visit

end

def get_relationship(per)
  if per.guardianrelation == 'SPO'
    relationship = 12
  elsif per.guardianrelation == 'SIS'
    relationship = 2
  elsif per.guardianrelation == 'BRO'
    relationship = 2
  elsif per.guardianrelation == 'MTH'
    relationship = 3
  elsif per.guardianrelation == 'FTH'
    relationship = 3
  elsif per.guardianrelation == 'OTH'
    relationship = 13
  else
    relationship = 13
  end

  return relationship
end

start