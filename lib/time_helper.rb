module TimeHelper
  
  def start_date_number
    num = date_to_number(start_year, start_month)
    num <= 12 ? 0 : num
  end
  
  def end_date_number(current_date_number)
    num = date_to_number(end_year, end_month)
    start = start_date_number
    num = current_date_number if num == 0 && start > 0
    num = 0 if num <= 12 || start == 0
    num < start ? start : num
  end
  
  def current?
    end_year.blank? && end_month.blank?
  end
  
  def date_to_number(year, month)
    year.to_i * 12 + month.to_i
  end
end