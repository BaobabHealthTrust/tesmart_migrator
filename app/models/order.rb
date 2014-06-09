class Order < ActiveRecord::Base
	set_table_name "orders"
	set_primary_key :order_id
  has_many :observations, :foreign_key => :order_id
  has_many :drug_orders, :foreign_key => :order_id
  belongs_to :encounter, :foreign_key => :encounter_id
  belongs_to :user, :foreign_key => :user_id

	

end
