#!/bin/bash

USERNAME=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['bart2']['username']"`
PASSWORD=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['bart2']['password']"`
DATABASE=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['bart2']['database']"`
HOST=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['bart2']['host']"`

now=$(date +"%F %T")
echo "start time : $now"

echo "initializing $DATABASE (OpenMRS 1.7) destination database.............................."

mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/bart2_views_schema_additions.sql
echo "loading defaults"
echo "loading up-to-date concepts"
mysql  --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/openmrs_metadata_1_7.sql
mysql  --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/temporary_tables.sql

echo "loading import scripts.............................."

FILES=import_scripts/*.sql
for f in $FILES
do
	echo "loading $f..."
	mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < $f
done

echo "loading recalculating adherence scripts"
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/adherence_calculation.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/recalculate_adherence.sql

echo "updating current_location_id"
script/runner script/current_location_id.rb

echo "importing data......................................."
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE<<EOFMYSQL
CALL proc_import_patients;
EOFMYSQL

echo "creating dispensation, appointment and exit from HIV care encounters....."
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST $DATABASE<<EOFMYSQL
CALL proc_import_from_temp;
EOFMYSQL

echo "calculating adherence................................"

mysql --user=$USERNAME --password=$PASSWORD --host=$HOST $DATABASE<<EOFMYSQL
CALL proc_update_obs_order_id;
EOFMYSQL

echo "fixing retired drugs"
script/runner script/all_after_migration_scripts/fix_program_locations.rb

echo "fixing equivalent daily dose"
script/runner script/all_after_migration_scripts/fix_for_equivalent_daily_dose.rb

echo "adding the hanging pills"
script/runner script/all_after_migration_scripts/include_hanging_pills_to_drug_orders.rb

echo "recalculating adherence"
script/runner script/all_after_migration_scripts/recalculate_adherence.rb

echo "fixing earliest_start_date"
script/runner script/all_after_migration_scripts/fix_earliest_start_date.rb

echo "fixing all patients on HIV program and on ARVs without any dispensing encounter"
script/runner script/all_after_migration_scripts/patients_on_hiv_prog_without_disp_enc_fix.rb

echo "fixing all patients with Pre-ART state but are not on HIV program"
script/runner script/all_after_migration_scripts/pre_art_hiv_program_fix.rb

echo "deleting temp_encounter and temp_obs tables..........."
mysql --user=$USERNAME --password=$PASSWORD $DATABASE<<EOFMYSQL
  DROP table temp_obs;
  DROP table temp_encounter;
EOFMYSQL

later=$(date +"%F %T")
echo "start time : $now"
echo "end time : $later"

echo "done"
