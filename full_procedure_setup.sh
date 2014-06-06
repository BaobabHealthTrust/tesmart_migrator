#!/bin/bash
usage(){
  echo "Usage: $0 SITE"
  echo
  echo "ENVIRONMENT should be: bart2"
  echo "Available SITES:"
  ls -1 db/data
} 

SITE=$1

if [ -z "$SITE" ] ; then
    usage
    exit
fi


USERNAME=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['bart2']['username']"`
PASSWORD=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['bart2']['password']"`
DATABASE=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['bart2']['database']"`
HOST=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['bart2']['host']"`

now=$(date +"%F %T")
echo "start time : $now"

echo "initializing $DATABASE (OpenMRS 1.7) destination database.............................."

echo "DROP DATABASE $DATABASE;" | mysql --user=$USERNAME  --host=$HOST --password=$PASSWORD
echo "CREATE DATABASE $DATABASE;" | mysql --user=$USERNAME  --host=$HOST --password=$PASSWORD
echo "loading concept_server_full_db"
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/openmrs_1_7_2_concept_server_full_db.sql
echo "loading schema additions"
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/schema_bart2_additions.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/bart2_views_schema_additions.sql
echo "loading defaults"
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/defaults.sql
echo "loading user schema modifications"
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/malawi_regions.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/mysql_functions.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/drug_ingredient.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/pharmacy.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/national_id.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/weight_for_heights.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/data/${SITE}/${SITE}.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/data/${SITE}/tasks.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/moh_regimens_only.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/retrospective_station_entries.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/create_dde_server_connection.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/migration_imports/create_weight_height_for_ages.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/migration_imports/insert_weight_for_ages.sql
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST  $DATABASE < db/age_in_months.sql

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
#
#echo "fixing retired drugs"
#script/runner script/all_after_migration_scripts/fix_program_locations.rb

#echo "fixing equivalent daily dose"
#script/runner script/all_after_migration_scripts/fix_for_equivalent_daily_dose.rb

#echo "adding the hanging pills"
#script/runner script/all_after_migration_scripts/include_hanging_pills_to_drug_orders.rb

#echo "recalculating adherence"
#script/runner script/all_after_migration_scripts/recalculate_adherence.rb

#echo "fixing earliest_start_date"
#script/runner script/all_after_migration_scripts/fix_earliest_start_date.rb

#echo "fixing all patients on HIV program and on ARVs without any dispensing encounter"
#script/runner script/all_after_migration_scripts/patients_on_hiv_prog_without_disp_enc_fix.rb 

#echo "fixing all patients with Pre-ART state but are not on HIV program"
#script/runner script/all_after_migration_script/pre_art_hiv_program_fix.rb

echo "deleting temp_encounter and temp_obs tables..........."
mysql --user=$USERNAME --password=$PASSWORD $DATABASE<<EOFMYSQL
  DROP table temp_obs;
  DROP table temp_encounter;
EOFMYSQL

later=$(date +"%F %T")
echo "start time : $now"
echo "end time : $later"

echo "done"
