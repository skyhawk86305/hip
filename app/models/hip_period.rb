class HipPeriod < SwareBase

  set_table_name("hip_period_v")
  set_primary_key :period_id

  has_many :missed_scans, :primary_key=>:missed_scan_id, :foreign_key=>:period_id

  before_save :set_lu_data

  named_scope :current_period, :conditions=>"month_of_year=month(current_timestamp)
        and year=year(current_timestamp) and org_l1_id=0 and org_id=0"
        
  def self.populate_additional_periods(months)
    sql = "with max_year as (
    select *
    from hip_period_v
    where year = (select max(year) from hip_period_v)
    )
    select *
    from max_year
    where month_of_year = (select max(month_of_year) from max_year)"

    max_period = find_by_sql(sql)

    if max_period.empty?
      base_time = Time.gm(Time.now.year, Time.now.month, 1)
    else
      max_period = max_period[0]
      base_time = Time.gm(max_period.year, max_period.month_of_year, 1)
    end
    months.times do |i|
      asset_freeze_timestamp = ((base_time + (1+i).month).weekday? ? 1 : 2).weekdays_from(base_time + (1+i).month) + 12.hours
      new_period = {:org_l1_id => 0, :org_id => 0, :year => asset_freeze_timestamp.year, :month_of_year => asset_freeze_timestamp.month,
        :asset_freeze_timestamp => asset_freeze_timestamp, :lu_userid => SwareBase.username(), :lu_timestamp => Time.now.gmtime}
      create!(new_period)
    end
  end
  
end
