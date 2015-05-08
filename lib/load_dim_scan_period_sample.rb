class LoadDimScanPeriodSample
  
  MONTH_TO_QUARTER = [0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4]
  
  MONTH_TO_MONTH_OF_QUARTER = [0, 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3]
  
  def self.load()
    beginning_date = (Date.current - 2.months).beginning_of_month
    ending_date = (Date.current + 2.months).end_of_month
    date = beginning_date
    id = 1
    periods = []
    while date <= ending_date
      periods << {
        :period_month_id => id,
        :year => date.year,
        :quarter_id => (date.year - 1999) * 4 + ( MONTH_TO_QUARTER[date.month] - 1 ),
        :quarter_of_year => MONTH_TO_QUARTER[date.month],
        :month_name => Date::MONTHNAMES[date.month].downcase,
        :month_of_year => date.month,
        :month_of_quarter => MONTH_TO_MONTH_OF_QUARTER[date.month],
        :days_in_month => date.end_of_month.day
      }
      date += 1.month
      id += 1
    end
    ScanPeriod.create!(periods)
  end
  
end