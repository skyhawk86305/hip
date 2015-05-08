class ReportingTableFactsScanPeriod
  
  TABLE_NAME = 'facts_scan_period_v'

  def self.load

    insert = "with scans as (
      select *
      from dim_scan_scan_period_v as scan
      where scan_id = (select scan_id
        from dim_scan_scan_period_v 
        where asset_vid = scan.asset_vid 
        and period_month_id = scan.period_month_id
        order by case when publish_ready_timestamp is null then '9999-12-31 23:59:59.9' else publish_ready_timestamp end desc 
        fetch first 1 row only)
    )
    select * from final table (
    insert into #{TABLE_NAME} (
    PERIOD_MONTH_ID,
    FINDING_VID,
    ORG_L1_ID,
    ORG_ID,
    ASSET_VID,
    TOOL_ID,
    SCAN_ID,
    VULN_ID,
    VALIDATE_FLAG,
    SUPPRESS_FLAG,
    SUPPRESS_ID,
    SUPPRESS_CNT,
    RELEASE_FLAG,
    AUTO_RELEASE_FLAG,
    RELEASE_DATE_ID,
    PUBLISH_FLAG,
    PUBLISH_DATE_ID,
    PORT,
    SEVERITY_ID,
    FINDING_ID,
    PROTOCOL_ID,
    CAT_NAME,
    LU_TIMESTAMP,
    RESULT,
    FINDING_TEXT
    ) (select
    assp.PERIOD_MONTH_ID,
    finding.FINDING_VID,
    assp.ORG_L1_ID,
    assp.ORG_ID,
    assp.ASSET_VID,
    scan.TOOL_ID,
    scan.SCAN_ID,
    finding.VULN_ID,
    'n' as validate_flag,
    case when supp.suppress_id is not null then 'y' else 'n' end as suppress_flag,
    hsupf.suppress_id as SUPPRESS_ID,
    case when supp.suppress_id is not null then 1 else 0 end as SUPPRESS_CNT,
    case when scan.publish_ready_timestamp is null then 'n' else 'y' end as RELEASE_FLAG,
    'n' as AUTO_RELEASE_FLAG,
    coalesce(drelease.date_id, 0) as RELEASE_DATE_ID,
    case when scan.publish_timestamp is null then 'n' else 'y' end as PUBLISH_FLAG,
    coalesce(dpublish.date_id, 0) as PUBLISH_DATE_ID,
    finding.PORT,
    finding.SEVERITY_ID,
    finding.FINDING_ID,
    finding.PROTOCOL_ID,
    coalesce(finding.cat_name, vuln.sarm_cat_name, 'unk') as CAT_NAME,
    current_timestamp,
    'prevalid' as RESULT,
    finding.FINDING_TEXT
    from dim_scan_asset_period_v as assp
    join scans as scan on scan.asset_vid = assp.asset_vid and scan.period_month_id = assp.period_month_id
    join fact_scan_v as finding on finding.asset_id = assp.asset_id 
      and finding.org_l1_id = assp.org_l1_id 
      and finding.org_id = assp.org_id
      and scan.scan_start_timestamp between finding.row_from_timestamp and coalesce(finding.row_to_timestamp, current_timestamp)
      and finding.scan_service = 'health'
      and finding.severity_id=5
      and finding.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})
      and finding.scan_tool_id = scan.tool_id
    join dim_scan_org_period_v as org on org.org_l1_id = assp.org_id and org.org_id = assp.org_id and org.period_month_id = assp.period_month_id
    join dim_comm_vuln_v as vuln on vuln.vuln_id = finding.vuln_id
    left join HIP_SCAN_FINDING_SUPPRESS_V as supp on supp.org_l1_id = assp.org_l1_id and supp.org_id = assp.org_id and supp.finding_id = finding.finding_id
      and scan.scan_start_timestamp between supp.finding_start_timestamp and coalesce(finding_end_timestamp, current_timestamp)
      and current_timestamp between supp.suppress_start_timestamp and supp.suppress_end_timestamp
    left join dim_comm_date_v as drelease on drelease.date = date(scan.publish_ready_timestamp)
    left join dim_comm_date_v as dpublish on dpublish.date = date(publish_timestamp)
    left join hip_suppress_finding_v as hsupf on hsupf.finding_id = finding.finding_id
    ))"
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