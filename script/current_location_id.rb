
Destination_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

CONN = ActiveRecord::Base.connection

def start

  testmart_hospital = TesmartHospital.first rescue nil

  unless testmart_hospital.blank?
    @bart1_current_location_name = testmart_hospital.h_name

    @site_code = testmart_hospital.arv_no_lead.delete("-") rescue ""

    @bart2_current_location_id = Location.find_by_name(@bart1_current_location_name).location_id rescue nil
    puts @bart2_current_location_id
    unless @bart2_current_location_id.blank?
      update_current_location_id = "UPDATE #{Destination_db}.global_property
                  SET property_value = #{@bart2_current_location_id}
                  WHERE property = 'current_health_center_id'"

      CONN.execute update_current_location_id

      update_current_location_name = "UPDATE #{Destination_db}.global_property
                  SET property_value = '#{@bart1_current_location_name}'
                  WHERE property = 'current_health_center_name'"

      CONN.execute update_current_location_name

      update_site_code = "UPDATE #{Destination_db}.global_property
                  SET property_value = '#{@bart1_current_location_site_code}'
                  WHERE property = 'site_prefix'"

      CONN.execute update_site_code
    end

  end

end

start
