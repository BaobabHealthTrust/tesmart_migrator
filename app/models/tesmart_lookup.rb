class TesmartLookup < ActiveRecord::Base
  set_table_name :code_file
  #method definitions
def self.load_villages
     village = self.find( :all, :conditions => "item_type = 'U9001'")
end
def self.load_traditional_authority
     traditional_authority = self.find( :all, :conditions => "item_type = 'U9004'")
end
def self.load_districts
     district = self.find( :all, :conditions => "item_type = 'U9005'")
end
def self.load_occupation_data
     district = self.find( :all, :conditions => "item_type = 'KM0003'")
end
end
