$person_id = 2
def start

  patients = TesmartPatient.all

  count = patients.length
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
  #Add more attributes
  new.save

  $person_id +=1

  create_guardian(t_patient, new_patient.id)

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