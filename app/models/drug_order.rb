class DrugOrder < ActiveRecord::Base
	set_table_name "drug_order"
  set_primary_key "drug_order_id"
  belongs_to :drug, :foreign_key => :drug_inventory_id
  belongs_to :order
  
end
