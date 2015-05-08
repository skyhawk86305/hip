class SuppressionDetailReportSearch
  
  #
  # Disable calls to new from outside the class
  #
  private_class_method :new
  
  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end

  def self.search(params)
    search_params = new(params)
    search_params.search
  end
  
  def search
    result = SwareBase.find_by_sql(sql)
    return result
  end
  
  #########
  private
  #########
  
  def initialize(params)
    @params = params
  end
  
  def sql
    if @params[:start_date].blank? and @params[:end_date].blank?
      date_limit = "and scan.publish_ready_timestamp between current_timestamp - 30 days
       and '9999-12-31 23:59:59.9'"
    else
      date_limit = "and scan.publish_ready_timestamp between '#{@params[:start_date]}'
       and '#{@params[:end_date]}'"
    end
    return <<-END_OF_QUERY    
          with suppressions as (
select org.org_name,
org.org_l1_id,
org.org_id,
sup.suppress_name,
sup.suppress_id
from hip_suppress_v as sup
join dim_comm_org_v as org on org.org_l1_id=sup.org_l1_id and org.org_id=sup.org_id
where #{SwareBase.quote_value(@params[:end_date])} between start_timestamp and end_timestamp
),
-- For in Cycle, return finding suppession counts by tool, scan, and supprression
-- Each row before groupping is a suppressed finding
-- each output row is a scan
in_cycle_findings as (
select sup.suppress_id,sup.org_name, sh.tool_id,scan.scan_type,scan.scan_id,count(sf.finding_id) as suppressed_finding_count
from  fact_scan_v as fs
join hip_suppress_finding_v as sf on sf.finding_id=fs.finding_id
join suppressions as sup on sup.suppress_id=sf.suppress_id
join dim_comm_tool_asset_scan_hist_v as sh on sh.asset_id=fs.asset_id
and sh.org_l1_id=sup.org_l1_id and sh.org_id=sup.org_id
join hip_scan_v as scan on scan.scan_id=sh.scan_id  and scan.scan_type='HC Cycle'
    and scan.publish_ready_timestamp is not null
    #{date_limit}
where  fs.org_l1_id=sup.org_l1_id 
        and fs.org_id=sup.org_id 
        and fs.asset_id = sh.asset_id
        and sh.scan_start_timestamp between fs.row_from_timestamp and coalesce(fs.row_to_timestamp, current_timestamp)
        and fs.severity_id=5
        and fs.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})
        and fs.scan_tool_id = sh.tool_id
        and fs.scan_service = 'health'
group by sup.suppress_id,sup.org_name, sh.tool_id ,scan.scan_id,scan.scan_type
),
--select * from in_cycle_findings
-- each output row is a suppression/tool combination
in_cycle_scans as (
select suppress_id,
org_name,
inf.scan_type,
tool_id,
count(*) as scan_count,
sum(suppressed_finding_count) as suppression_count,
count(case when scan.publish_ready_timestamp is null then null else 1 end) as scans_released_count
from in_cycle_findings as inf
join hip_scan_v as scan on scan.scan_id=inf.scan_id
group by suppress_id,org_name, inf.scan_type, tool_id
),
--select * from in_cycle_scans
ooc_findings as (
-- For Out of Cycle, return finding suppression counts by suppression, scan_type, tool_id, suppression_count
select sup.suppress_id, sup.org_name,sh.tool_id,scan.ooc_scan_type,scan.scan_id,count(sf.finding_id) as suppressed_finding_count
from  fact_scan_v as fs
join hip_suppress_finding_v as sf on sf.finding_id=fs.finding_id
join suppressions as sup on sup.suppress_id=sf.suppress_id
join dim_comm_tool_asset_scan_hist_v as sh on sh.asset_id=fs.asset_id
and sh.org_l1_id=sup.org_l1_id and sh.org_id=sup.org_id
join hip_ooc_scan_v as scan on scan.scan_id=sh.scan_id
    and scan.publish_ready_timestamp is not null
    #{date_limit}
where  fs.org_l1_id=sup.org_l1_id
        and fs.org_id=sup.org_id 
        and fs.asset_id = sh.asset_id
        and sh.scan_start_timestamp between fs.row_from_timestamp and coalesce(fs.row_to_timestamp, current_timestamp)
        and fs.severity_id=5
        and fs.scan_tool_id = sh.tool_id
        and fs.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})
        and fs.scan_service = 'health'
group by sup.suppress_id, sup.org_name,sh.tool_id ,scan.scan_id,scan.ooc_scan_type
)
--select * from ooc_findings
,
-- Each output row is a suppression/scan_type/tool
ooc_scans as (
select suppress_id,
org_name,
oocf.ooc_scan_type,
oocf.tool_id,
count(*) as scan_count,
sum(suppressed_finding_count) as suppression_count,
count(case when scan.publish_ready_timestamp is null then null else 1 end) as scans_released_count
from ooc_findings as oocf
join hip_ooc_scan_v as scan on scan.scan_id=oocf.scan_id
group by suppress_id,org_name, oocf.ooc_scan_type, oocf.tool_id
)
--select * from ooc_scans
,
union as (
select suppress_id,org_name, scan_type, tool_id, scan_count, suppression_count,scans_released_count
from in_cycle_scans
union
select suppress_id,org_name, ooc_scan_type as scan_type, tool_id, scan_count, suppression_count,scans_released_count
from ooc_scans
)
select
union.org_name,
sup.suppress_name,
sup.suppress_class,
sup.start_timestamp,
sup.end_timestamp,
union.scan_type,
tool.manager_name,
union.scans_released_count,
union.suppression_count
from union
join hip_suppress_v as sup on sup.suppress_id=union.suppress_id
join dim_comm_tool_v as tool on tool.tool_id = union.tool_id
order by union.org_name, sup.suppress_name
    END_OF_QUERY
  end
  
end
