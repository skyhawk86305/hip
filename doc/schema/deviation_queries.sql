-- query 1
select
        fp.scan_id, 
        fp.finding_id,
        fp.finding_vid, 
        dsap.asset_vid,
        dssp.publish_ready_timestamp,
        dsap.hc_group_name as group_name, 
        dsap.hc_group_id, 
        'y' as valid_finding_flag,
        dsap.host_name
from hip.dim_scan_asset_period_v as dsap
JOIN hip.dim_scan_scan_period_v AS dssp ON dsap.asset_vid = dssp.asset_vid
        AND dsap.org_l1_id = dssp.org_l1_id
        AND dsap.org_id = dssp.org_id
        AND dsap.period_month_id = dssp.period_month_id
join hip.facts_scan_period_v as fp on dsap.org_l1_id = fp.org_l1_id
        and dsap.org_id = fp.org_id
        and dsap.period_month_id = fp.period_month_id
        and dsap.asset_vid = fp.asset_vid
        and fp.severity_id = 5
        and fp.tool_id = dssp.tool_id
join dim_comm_severity_v as sev on sev.severity_id = fp.severity_id
JOIN hip.dim_comm_vuln_v AS vuln ON vuln.vuln_id=fp.vuln_id
JOIN hip.fact_scan_v as fact ON fact.finding_vid = fp.finding_vid
JOIN hip.dim_comm_os_v os ON os.os_id = dsap.os_id
where dsap.period_month_id = 3
        and dsap.org_l1_id = 3568
        and dsap.org_id = 3568 AND dsap.hc_group_id = 420 AND dsap.system_status='prod' AND dssp.publish_ready_timestamp is null AND fp.vuln_id not in (135972)


-- query 2
select * from hip.dim_scan_asset_period_v 
where period_month_id = 3 and org_l1_id = 3568 and org_id = 3568 
AND hc_group_id = 420 AND system_status='prod'

-- query 3
select *
from hip.dim_scan_asset_period_v as dsap
where dsap.period_month_id = 3
        and dsap.org_l1_id = 3568
        and dsap.org_id = 3568 AND dsap.hc_group_id = 420 AND dsap.system_status='prod'

-- query 4
select *
from hip.dim_scan_asset_period_v as dsap
where dsap.period_month_id = 3
        and dsap.org_l1_id = 3568
        and dsap.org_id = 3568 AND dsap.hc_group_id = 420 AND dsap.system_status='prod'
