class ReportingTableScanOrgPeriod
  
  TABLE_NAME = 'dim_scan_org_period_v'

  def self.load

    insert = "insert into #{TABLE_NAME} (
    org_l1_id, 
    org_id, 
    period_month_id, 
    year, 
    quarter_id, 
    quarter_of_year, 
    month_name, 
    month_of_year, 
    month_of_quarter, 
    days_in_month,
    period_override_flag,
    hip_period_id,
    asset_freeze_timestamp
    ) 
    select o.org_l1_id, 
    o.org_id, 
    sp.period_month_id, 
    sp.year, 
    sp.quarter_id, 
    sp.quarter_of_year, 
    sp.month_name, 
    sp.month_of_year,
    sp.month_of_quarter, 
    sp.days_in_month,
    case when hp.org_id = 0 then 'n' else 'y' end,
    hp.period_id,
    hp.asset_freeze_timestamp
    from dim_scan_period_v as sp
    cross join dim_comm_org_v as o
    join hip_period_v as hp on hp.year = sp.year and hp.month_of_year = sp.month_of_year and hp.org_id in (o.org_id, 0) and hp.org_id in (o.org_id, 0)
    where 
    o.org_service_hip = 'y'
    and hp.org_id = (select max(org_id) from hip_period_v as hp2 where hp2.month_of_year = sp.month_of_year and hp2.year = sp.year and (hp2.org_l1_id in (o.org_l1_id, 0)) and (hp2.org_id in (o.org_id, 0))) 
    "
    SwareBase.transaction do
      clear
      SwareBase.connection.execute(insert)
    end
  end
  
  def self.clear
    delete = "delete from #{TABLE_NAME}"
    SwareBase.transaction do
      SwareBase.connection.execute(delete)
    end
  end      

end