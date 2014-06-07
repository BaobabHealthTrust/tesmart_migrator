CREATE INDEX encounter_pid_type_idx ON encounter(patient_id, encounter_type);
CREATE INDEX patient_name_id_voided_idx ON patient_name(patient_id,voided);
CREATE INDEX patient_identifier_id_voided_idx ON patient_identifier(patient_id,voided);
CREATE INDEX observation_concept_id_patid_idx ON obs(patient_id,concept_id);







