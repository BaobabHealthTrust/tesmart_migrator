class TesmartPatient < ActiveRecord::Base
  set_table_name :patient
  set_primary_key :arv_no

  def birthday
    return "#{self.birth_year}" + "-" + "#{self.birth_month}" + "-" + "#{self.birth_Day}"
  end

  def age(day = Date.today)
    (day.year - self.birthday.to_date.year).to_i
  end
end
