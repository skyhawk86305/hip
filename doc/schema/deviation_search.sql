With deviation as (
  SELECT
    fp.scan_id,
    fp.finding_id,
    fp.finding_vid,
    fp.finding_text,
    dsap.host_name,
    dsap.ip_string_list,
    dsap.hc_group_name group_name,
    dsap.hc_group_id,
    dsap.org_l1_id,
    dsap.org_id,
    dsap.asset_id,
    vuln.title,
    vuln.sarm_cat_name,
    os.os_product,
    dssp.scan_start_timestamp,
    dssp.publish_ready_timestamp,
    tool.manager_name,
    sfs1.suppress_id,
    fact.cat_name,
    fact.finding_hash,
    sfs1.lu_timestamp as suppress_date,
    hsup.suppress_name,
    hsup.suppress_class,
    CASE WHEN sfs1.finding_id is NOT NULL THEN 'Suppressed' ELSE 'Valid' END AS validation_status,
    CASE WHEN sev.severity_cd = 'allowed' 
      THEN 'compliant' --          WHEN sev.severity_cd = 'low' THEN 'warning'
        WHEN sev.severity_cd = 'high' THEN 'violation'
        ELSE sev.severity_cd
      END AS deviation_level
  FROM hip.dim_scan_asset_period_v AS dsap
  JOIN hip.dim_scan_scan_period_v AS dssp
  ON dsap.asset_vid = dssp.asset_vid
    AND dsap.org_l1_id = dssp.org_l1_id
    AND dsap.org_id = dssp.org_id
    AND dsap.period_month_id = dssp.period_month_id
  JOIN hip.dim_scan_org_period_v dsop
  ON dsap.period_month_id = dsop.period_month_id
    AND dsap.org_l1_id = dsop.org_l1_id
    AND dsap.org_id = dsop.org_id
  JOIN hip.facts_scan_period_v AS fp
  ON dsap.org_l1_id = fp.org_l1_id
    AND dsap.org_id = fp.org_id
    AND dsap.period_month_id = fp.period_month_id
    AND dsap.asset_vid = fp.asset_vid
    and fp.severity_id=5
    and dssp.tool_id = fp.tool_id
  JOIN hip.dim_comm_severity_v AS sev
    ON sev.severity_id = fp.severity_id          
  JOIN hip.dim_comm_os_v os
    ON os.os_id = dsap.os_id
  JOIN hip.dim_comm_vuln_v AS vuln
    ON vuln.vuln_id=fp.vuln_id
  JOIN hip.dim_comm_tool_v AS tool
    ON tool.tool_id = dssp.tool_id
  JOIN hip.fact_scan_v as fact
    ON fact.finding_vid = fp.finding_vid
    AND fact.severity_id=5
  LEFT JOIN hip.hip_suppress_finding_v as sfs1
    ON sfs1.finding_id = fp.finding_id
  LEFT JOIN hip.hip_suppress_v as hsup
    ON hsup.suppress_id = sfs1.suppress_id
  LEFT JOIN hip.dim_scan_suppress_period_v dsup
    ON dsup.period_month_id = fp.period_month_id
    AND dsup.suppress_id = sfs1.suppress_id
  WHERE
    dsap.period_month_id = #{SwareBase.current_month_period_id}
    AND dsap.org_l1_id = #{l1id}
    AND dsap.org_id = #{id}
    AND #{conditions.to_s}
),
deviation_with_row_num as ( -- WITH
  SELECT
    cast(null as integer) as count,
    scan_id,
    finding_id,
    finding_vid,
    cat_name,
    finding_hash,
    finding_text,
    host_name,
    ip_string_list,
    group_name,
    hc_group_id,
    org_l1_id,
    org_id,
    asset_id,
    title,
    sarm_cat_name,
    os_product,
    scan_start_timestamp,
    publish_ready_timestamp,
    manager_name,
    suppress_id,
    suppress_date,
    suppress_name,
    suppress_class,
    validation_status,
    deviation_level,
    row_number() over(ORDER BY #{order_fragment}) as row
  FROM deviation
)
SELECT * FROM deviation_with_row_num
WHERE row BETWEEN #{@rows_from} AND #{@rows_to}
UNION
SELECT count(*) as count,
cast(null as integer) as scan_id,
cast(null as integer) as finding_id,
cast(null as integer) as finding_vid,
cast(null as varchar(1)) as cat_name,
cast(null as varchar(1)) as finding_hash,
cast(null as varchar(1)) as finding_text,
cast(null as varchar(1)) as host_name,
cast(null as varchar(1)) as ip_string_list,
cast(null as varchar(1)) as group_name,
cast(null as integer) as hc_group_id,
cast(null as integer) as org_l1_id,
cast(null as integer) as org_id,
cast(null as integer) as asset_id,
cast(null as varchar(1)) as title,
cast(null as varchar(1)) as sarm_cat_name,
cast(null as varchar(1)) as os_product,
cast(null as timestamp) as scan_start_timestamp,
cast(null as timestamp) as publish_ready_timestamp,
cast(null as varchar(1)) as manager_name,
cast(null as integer) as suppress_id,
cast(null as timestamp) as suppress_date,
cast(null as varchar(1)) as suppress_name,
cast(null as varchar(1)) as suppress_class,
cast(null as varchar(1)) as validation_status,
cast(null as varchar(1)) as deviation_level,
cast(null as integer) as row
FROM deviation_with_row_num
ORDER BY count asc, #{order_fragment} -- END OF QUERY")
