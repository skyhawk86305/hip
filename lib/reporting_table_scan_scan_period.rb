class ReportingTableScanScanPeriod
  
  TABLE_NAME = 'dim_scan_scan_period_v'

  def self.load

    insert = "insert into #{TABLE_NAME} (
    PERIOD_MONTH_ID,
    SCAN_ID,
    ORG_L1_ID,
    ORG_ID,
    ASSET_VID,
    TOOL_ID,
    TOOL_NAME,
    SCAN_DATE_ID,
    SCAN_START_TIMESTAMP,
    SCAN_STOP_TIMESTAMP,
    SCAN_TYPE,
    PUBLISH_READY_TIMESTAMP,
    PUBLISH_READY_USERID,
    PUBLISH_TIMESTAMP,
    PUBLISH_DATE_ID,
    LU_TIMESTAMP )
    (select
    assp.PERIOD_MONTH_ID,
    scan.SCAN_ID,
    assp.ORG_L1_ID,
    assp.ORG_ID,
    assp.ASSET_VID,
    scan.TOOL_ID,
    tool.TOOL_NAME,
    (select date_id from dim_comm_date_v where date(scan_start_timestamp) = date),
    scan.SCAN_START_TIMESTAMP,
    scan.SCAN_STOP_TIMESTAMP,
    hscan.SCAN_TYPE,
    hscan.PUBLISH_READY_TIMESTAMP,
    hscan.PUBLISH_READY_USERID,
    hscan.PUBLISH_TIMESTAMP,
    (select date_id from dim_comm_date_v where date(publish_timestamp) = date),
    current_timestamp
    from dim_scan_asset_period_v as assp
    join dim_scan_period_v as period on period.period_month_id = assp.period_month_id
    join dim_comm_tool_asset_scan_hist_v as scan on scan.asset_id = assp.asset_id and scan.org_l1_id = assp.org_l1_id and scan.org_id = assp.org_id
      and year(scan.scan_start_timestamp) = period.year and month(scan.scan_start_timestamp) = period.month_of_year
      and scan.scan_service = 'health'
    join hip_scan_v as hscan on hscan.scan_id = scan.scan_id
    join dim_comm_tool_v as tool on tool.tool_id = scan.tool_id
    where hscan.lu_timestamp = (select max(hscan2.lu_timestamp) from hip_scan_v as hscan2 join dim_comm_tool_asset_scan_hist_v as scan2 on scan2.scan_id = hscan2.scan_id where scan2.asset_id = assp.asset_id)
    )"
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