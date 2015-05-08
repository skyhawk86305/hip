class ScanPeriod < SwareBase

  set_table_name("dim_scan_period_v")
  set_primary_keys :period_month_id

  named_scope :current_period, :conditions=>"month_of_year=month(current_timestamp)
        and year=year(current_timestamp)"

end
