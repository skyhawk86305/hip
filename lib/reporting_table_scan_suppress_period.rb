class ReportingTableScanSuppressPeriod
  
  TABLE_NAME = 'dim_scan_suppress_period_v'

  def self.load

    insert = "insert into #{TABLE_NAME} (
    PERIOD_MONTH_ID,
    SUPPRESS_ID,
    ORG_L1_ID,
    ORG_ID,
    SUPPRESS_NAME,
    SUPPRESS_DESC,
    SUPPRESS_START_TIMESTAMP,
    SUPPRESS_START_DATE_ID,
    SUPPRESS_STOP_TIMESTAMP,
    SUPPRESS_STOP_DATE_ID,
    SUPPRESS_CLASS,
    SUPPRESS_STATUS,
    SUPPRESS_AUTO_FLAG,
    SUPPRESS_SCOPE,
    VULN_ID,
    ASSET_VID,
    ASSET_ID,
    LU_TIMESTAMP
    )
    (select 
    sp.PERIOD_MONTH_ID,
    sup.SUPPRESS_ID,
    sup.ORG_L1_ID,
    sup.ORG_ID,
    sup.SUPPRESS_NAME,
    sup.SUPPRESS_DESC,
    sup.START_TIMESTAMP,
    (select date_id from dim_comm_date_v where date = date(sup.start_timestamp)), --suppress_START_DATE_ID
    sup.end_TIMESTAMP,
    (select date_id from dim_comm_date_v where date = date(sup.end_timestamp)), --SUPPRESS_STOP_DATE_ID
    sup.SUPPRESS_CLASS,
    sup.approval_STATUS,
    sup.automatic_suppress_flag,
    sup.apply_to_scope,
    sup.VULN_ID,
    assh.tool_ASSET_VID,
    sup.ASSET_ID,
    current_timestamp
    from dim_scan_period_v as sp
    cross join hip_suppress_v as sup
    join hip_period_v as hp on hp.year = sp.year and hp.month_of_year = sp.month_of_year and hp.org_id in (sup.org_id, 0) and hp.org_id in (sup.org_id, 0)
    left join dim_comm_tool_asset_hist_v as assh on assh.tool_asset_id = sup.asset_id and assh.org_l1_id = sup.org_l1_id and assh.org_id = sup.org_id and hp.asset_freeze_timestamp between assh.row_from_timestamp and coalesce(assh.row_from_timestamp, current_timestamp)
    where
    hp.org_id = (select max(org_id) from hip_period_v as hp2 where hp2.month_of_year = sp.month_of_year and hp2.year = sp.year and (hp2.org_l1_id in (sup.org_l1_id, 0)) and (hp2.org_id in (sup.org_id, 0))) 
    and timestamp(trim(both from char(sp.year)) || '-' || trim(both from char(sp.month_of_year)) || '-01 00:00:01') between sup.start_timestamp and sup.end_timestamp
    )
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