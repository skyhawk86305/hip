module SuppressionsHelper

  def approval_status_list
    [["Unknown"],["Customer Approved"],["Customer Pending"]]
  end

  def classification_list
    #25 char limit on column
    [
      ["Cust approved exception"],
      # The following value was disabled at the request of the HC Project Office.
      #["Cust pending exception"],
      ["Cust owned responsibility"],
      ["Tool logic error"]
    ]
  end

  def scope_list
    [
      ['Account','account'],
      ['Health Check Group','group'],
      ['System Name','asset']

    ]
  end

  def bulk_style_display(value)
    if value=="y"
      "display: block;"
    end
    if value=="n" || value==nil
      "display:none;"
    end
  end

  # create a list of ymd values in array to display on
  # suppression form for start_timestamp
  # the day must always be the beginning of the month
  # pass orgininal date to include original date if it is in the past.
  def start_ymd_select_list(original_date = nil)
    ymd_array=[]
    date = Time.now #parse("2011-04-05 00:00:00")
    ymd_array << ["#{original_date.strftime("%Y-%m")}-#{original_date.beginning_of_month.strftime("%d")}"] unless original_date.nil?
    12.times do
      ymd_array << ["#{date.strftime("%Y-%m")}-#{date.beginning_of_month.strftime("%d")}"]
      date = date.next_month
    end
    return ymd_array
  end

  # create a list of ymd values in array to display on
  # suppression form for end_timestamp
  # the day must always be the end of the month
  def end_ymd_select_list(original_date = nil)
    ymd_array=[]
    date = Time.now
    ymd_array << ["#{original_date.strftime("%Y-%m")}-#{original_date.end_of_month.strftime("%d")}"] unless original_date.nil?
    12.times do
      ymd_array << ["#{date.strftime("%Y-%m")}-#{date.end_of_month.strftime("%d")}"]
      date = date.next_month
    end
    return ymd_array
  end
  
  def status_column(suppression)
    now = Time.now
    if now > suppression.end_timestamp
      return "<td style='font-weight:bold;background:red'>Expired</td>"
    elsif now.between?((suppression.end_timestamp  - 3.months), suppression.end_timestamp)
      return "<td style='font-weight:bold;background:yellow'>Expiring</td>"
    else
      return "<td style='font-weight:bold;background:green'>Current</td>"
    end
  end
end
