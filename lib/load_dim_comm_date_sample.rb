class LoadDimCommDateSample
  
  MONTH_TO_QUARTER = [0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4]
  
  MONTH_TO_MONTH_OF_QUARTER = [0, 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3]
  
  def self.load()
    beginning_date = (Date.current - 1.year).beginning_of_month
    ending_date = (Date.current + 1.year).end_of_month
    date = beginning_date
    id = 1
    dates = []
    dates << {:date_id => 0, :lu_userid => 'hip', :lu_timestamp => Time.now.utc}
    while date <= ending_date
      dates << {
        :date_id => id,
        :date => date,
        :year_id => date.year - 1999,
        :year => date.year,
        :quarter_id => (date.year - 1999) * 4 + ( MONTH_TO_QUARTER[date.month] - 1 ),
        :quarter_of_year => MONTH_TO_QUARTER[date.month],
        :month_id => (date.year - 1999) * 12 + (date.month - 1),
        :month_name => Date::MONTHNAMES[date.month].downcase,
        :month_of_year => date.month,
        :month_of_quarter => MONTH_TO_MONTH_OF_QUARTER[date.month],
        :week_id => (date.year - 1999) * 53 + date.to_time.strftime('%U').to_i,
        :weekiso_id => nil,
        :week_of_year => date.to_time.strftime('%U').to_i + 1,
        :weekiso_of_year => nil,
        :week_of_quarter => nil,
        :week_of_month => nil,
        :day_id => (date.year - 1999) * 356 + (date.yday),
        :day_of_month => date.day,
        :day_of_week => date.wday + 1,
        :day_of_year => date.yday,
        :day_name => Date::DAYNAMES[date.wday].downcase,
        :day_weekend_flag => date.weekday? ? 'n' : 'y',
        :day_weekpart => date.weekday? ? 'weekday' : 'weekend',
        :day_epoch_start => date.to_time.utc.tv_sec,
        :day_epoch_stop => (date - 1.day).to_time.utc.tv_sec,
        :lu_userid => 'hip',
        :lu_timestamp => Time.now.utc
      }
      date += 1.day
      id += 1
    end
    DimCommDate.create!(dates)
  end
  
end