class ReportHcCycleSearch
  
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
  
  def org_l1_id
    if @params['org_id'].respond_to?('[]')
      return @params['org_id'][0]
    else
      return @params['org_id'].split(',')[0]
    end
  end
  
  def org_id
    if @params['org_id'].respond_to?('[]')
      return @params['org_id'][1]
    else
      return @params['org_id'].split(',')[1]
    end
  end
  
  def sql
    return <<-END_OF_QUERY    
    with
    last_released_scan as (
      select asset_vid,
      scan_id,
      publish_ready_timestamp
      from dim_scan_scan_period_v as scanp
      where org_l1_id = #{org_l1_id}
      and org_id = #{org_id}
      and period_month_id = #{SwareBase.current_month_period_id}
      and scan_type = 'HC Cycle'
      and publish_ready_timestamp = (select max(publish_ready_timestamp) from dim_scan_scan_period_v where period_month_id = scanp.period_month_id and asset_vid = scanp.asset_vid)
      ),
    missing_scans as (
      select assp.asset_id, missed.missed_scan_reason_id
      from dim_scan_asset_period_v as assp
      left join (
        select ascan.scan_id, ascan.asset_id
        from dim_comm_tool_asset_scan_hist_v as ascan
        left join hip_ooc_scan_v as oscan on oscan.scan_id = ascan.scan_id
        where ascan.org_l1_id = #{org_l1_id}
        and ascan.org_id = #{org_id}
        and month(ascan.scan_start_timestamp) = month(current_timestamp)
        and year(ascan.scan_start_timestamp) = year(current_timestamp)
        and ascan.scan_service = 'health'
        and oscan.scan_id is null
        ) as scanh on scanh.asset_id = assp.asset_id
      left join hip_missed_scan_v as missed on missed.period_id = #{SwareBase.current_period_id} and missed.asset_id = assp.asset_id
      where assp.org_l1_id = #{org_l1_id}
      and assp.org_id = #{org_id}
      and assp.period_month_id = #{SwareBase.current_month_period_id}
      and assp.system_status = 'prod'
      and scanh.scan_id is null
      ),
    available as (
      select distinct ascan.asset_id
      from dim_comm_tool_asset_scan_hist_v as ascan
      left join hip_ooc_scan_v as oscan on oscan.scan_id = ascan.scan_id
      where ascan.org_l1_id = #{org_l1_id}
      and ascan.org_id = #{org_id}
      and month(ascan.scan_start_timestamp) = month(current_timestamp)
      and year(ascan.scan_start_timestamp) = year(current_timestamp)
      and ascan.scan_service = 'health'
      and oscan.scan_id is null
      ),
    deviations as(
      select
      asset_vid,
      scan_id,
      tool_id,
      count(*) as count,
      sum(case when suppress_flag = 'n' and validate_flag = 'y' then 1 else 0 end) as valid_count,
      sum(case when suppress_flag = 'y' then 1 else 0 end) as suppress_count
      from facts_scan_period_v
      where org_l1_id = #{org_l1_id}
      and org_id = #{org_id}
      and period_month_id = #{SwareBase.current_month_period_id}
      and severity_id=5
      group by asset_vid, scan_id, tool_id
      ),
    unreleased_scan_counts as (
      select scanp.asset_vid,
      count(*) as scan_count,
      coalesce(sum(count),0) as deviation_count,
      coalesce(sum(valid_count),0) as valid_count,
      coalesce(sum(suppress_count),0) as suppress_count
      from dim_scan_scan_period_v as scanp
      left join deviations as dev on dev.asset_vid = scanp.asset_vid and dev.scan_id = scanp.scan_id and dev.tool_id = scanp.tool_id
      where scanp.publish_ready_timestamp is null
      and scanp.period_month_id = #{SwareBase.current_month_period_id}
      group by scanp.asset_vid
      ),
    released_scan_counts as (
      select scanp.asset_vid,
      count(*) as scan_count,
      coalesce(sum(count),0) as deviation_count,
      coalesce(sum(valid_count),0) as valid_count,
      coalesce(sum(suppress_count),0) as suppress_count
      from dim_scan_scan_period_v as scanp
      left join deviations as dev on dev.asset_vid = scanp.asset_vid and dev.scan_id = scanp.scan_id and dev.tool_id = scanp.tool_id
      where scanp.publish_ready_timestamp is not null
      and scanp.period_month_id = #{SwareBase.current_month_period_id}
      group by scanp.asset_vid
      ),
    counts as
      (select hipgrps.group_name as group_name,
      hipgrps.hc_group_id,
      count(assp.asset_vid) as prod_count,
      sum(case when miss.asset_id is not null and miss.missed_scan_reason_id is null then 1 else 0 end) as miss_no_reason,
      sum(case when avail.asset_id is not null and uscanc.asset_vid is null and rscanc.asset_vid is null then 1 else 0 end) as none_labeled,
      sum(case when rscanc.asset_vid is null and uscanc.asset_vid is not null then 1 else 0 end) as none_released,
      sum(case when (miss.asset_id is not null and miss.missed_scan_reason_id is null) 
        or (avail.asset_id is not null and lrscan.asset_vid is null)
        or (lrscan.asset_vid is not null and lrscan.publish_ready_timestamp is null) then 1 else 0 end) as incomplete,
      sum(case when lrscan.publish_ready_timestamp is not null then 1 else 0 end) as released,
      sum(case when miss.asset_id is not null and miss.missed_scan_reason_id is not null then 1 else 0 end) as miss_reason,
      sum(case when (lrscan.publish_ready_timestamp is not null) or (miss.asset_id is not null and miss.missed_scan_reason_id is not null) then 1 else 0 end) as complete,
      sum(case when uscanc.scan_count is not null then uscanc.scan_count else 0 end) as unreleased_scan_count,
      sum(case when uscanc.scan_count is not null then uscanc.deviation_count - uscanc.valid_count - uscanc.suppress_count else 0 end) as unreleased_unvalidated_deviation_count,
      sum(case when uscanc.scan_count is not null then uscanc.suppress_count else 0 end) as unreleased_suppress_deviation_count,
      sum(case when uscanc.scan_count is not null then uscanc.valid_count else 0 end) as unreleased_valid_deviation_count,
      sum(case when rscanc.scan_count is not null then rscanc.scan_count else 0 end) as released_scan_count,
      sum(case when rscanc.scan_count is not null then rscanc.suppress_count else 0 end) as released_suppress_deviation_count,
      sum(case when rscanc.scan_count is not null then rscanc.valid_count else 0 end) as released_valid_deviation_count,
      sum(case when uscanc.scan_count is not null then uscanc.deviation_count else 0 end) as unreleased_deviation_count,
      sum(case when rscanc.scan_count is not null then rscanc.deviation_count else 0 end) as released_deviation_count
      from dim_scan_asset_period_v as assp
      left join available as avail on avail.asset_id = assp.asset_id
      left join last_released_scan as lrscan on lrscan.asset_vid = assp.asset_vid
      left join missing_scans as miss on miss.asset_id = assp.asset_id
      left join unreleased_scan_counts as uscanc on uscanc.asset_vid = assp.asset_vid
      left join released_scan_counts as rscanc on rscanc.asset_vid = assp.asset_vid
      right join (select group_name, hc_group_id from hip_hc_group_v
        where org_l1_id =  #{org_l1_id}
        and org_id =  #{org_id}
        and is_current = 'y') as hipgrps on hipgrps.hc_group_id = assp.hc_group_id
      where (assp.org_l1_id is null or assp.org_l1_id = #{org_l1_id})
      and (assp.org_id is null or assp.org_id =  #{org_id})
      and (assp.period_month_id is null or assp.period_month_id = #{SwareBase.current_month_period_id})
      and (assp.system_status is null or assp.system_status = 'prod')
      group by grouping sets ((hipgrps.group_name, hipgrps.hc_group_id),())
      ),
    not_current as (
      select
      hcg.group_name,
      hcg.hc_group_id,
      count (assh.tool_asset_id) as prod_count
      from hip_hc_group_v as hcg
      left join hip_asset_group_v as assg on assg.hc_group_id = hcg.hc_group_id
      left join dim_comm_tool_asset_hist_v as assh on assh.tool_asset_id = assg.asset_id
        and assh.org_l1_id = hcg.org_l1_id and assh.org_id = hcg.org_id
        and #{SwareBase.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between assh.row_from_timestamp and coalesce(assh.row_to_timestamp, current_timestamp)
      where hcg.is_current = 'n'
      and hcg.org_l1_id = #{org_l1_id}
      and hcg.org_id = #{org_id}
      and (assh.tool_asset_id is null or assh.system_status = 'prod')
      group by grouping sets ((hcg.group_name, hcg.hc_group_id),())
      ),
    unassigned as (
      select count(*) as prod_count
      from dim_comm_tool_asset_hist_v as assh
      left join hip_asset_group_v as assg on assg.asset_id = assh.tool_asset_id
      where assh.org_l1_id = #{org_l1_id}
      and assh.org_id = #{org_id}
      and #{SwareBase.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between assh.row_from_timestamp and coalesce(assh.row_to_timestamp, current_timestamp)
      and assh.system_status = 'prod'
      and assg.asset_id is null
      ),
    union_results as (
        select group_name,
        hc_group_id,
        'y' as is_current,
        prod_count,
        miss_no_reason,
        none_labeled,
        none_released,
        incomplete,
        released,
        miss_reason,
        complete,
        unreleased_scan_count,
        unreleased_unvalidated_deviation_count,
        unreleased_suppress_deviation_count,
        unreleased_valid_deviation_count,
        released_scan_count,
        released_suppress_deviation_count,
        released_valid_deviation_count ,
        unreleased_deviation_count,
        released_deviation_count
        from counts
      union
        select group_name,
        hc_group_id,
        'n' as is_current,
        prod_count,
        cast(null as integer) as miss_no_reason,
        cast(null as integer) as none_labeled,
        cast(null as integer) as none_released,
        cast(null as integer) as incomplete,
        cast(null as integer) as released,
        cast(null as integer) as miss_reason,
        cast(null as integer) as complete,
        cast(null as integer) as unreleased_scan_count,
        cast(null as integer) as unreleased_unvalidated_deviation_count,
        cast(null as integer) as unreleased_suppress_deviation_count,
        cast(null as integer) as unreleased_valid_deviation_count,
        cast(null as integer) as released_scan_count,
        cast(null as integer) as released_suppress_deviation_count,
        cast(null as integer) as released_valid_deviation_count,  
        cast(null as integer) as unreleased_deviation_count,  
        cast(null as integer) as released_valid_deviation_count  
        from not_current
      union
        select cast(null as varchar(1)) as group_name,
        cast(null as integer) as hc_group_id,
        cast(null as char(1)) as is_current,
        prod_count,
        cast(null as integer) as miss_no_reason,
        cast(null as integer) as none_labeled,
        cast(null as integer) as none_released,
        cast(null as integer) as incomplete,
        cast(null as integer) as released,
        cast(null as integer) as miss_reason,
        cast(null as integer) as complete,
        cast(null as integer) as unreleased_scan_count,
        cast(null as integer) as unreleased_unvalidated_deviation_count,
        cast(null as integer) as unreleased_suppress_deviation_count,
        cast(null as integer) as unreleased_valid_deviation_count,
        cast(null as integer) as released_scan_count,
        cast(null as integer) as released_suppress_deviation_count,
        cast(null as integer) as released_valid_deviation_count,
        cast(null as integer) as unreleased_valid_deviation_count,    
        cast(null as integer) as released_deviation_count
        from unassigned
      )
    select 
      group_name,
      hc_group_id,
      is_current,
      prod_count,
      miss_no_reason,
      none_labeled,
      none_released,
      incomplete,
      released,
      miss_reason,
      complete,
      unreleased_scan_count,
      unreleased_unvalidated_deviation_count,
      unreleased_suppress_deviation_count,
      unreleased_deviation_count - unreleased_suppress_deviation_count as unreleased_valid_deviation_count,
      --unreleased_valid_deviation_count,
      released_scan_count,
      released_suppress_deviation_count,
      released_valid_deviation_count,
      unreleased_deviation_count,  
      released_deviation_count - released_suppress_deviation_count as released_total_valid_deviation_count,
      --released_suppress_deviation_count + released_valid_deviation_count as released_total_valid_deviation_count,
      case when (released_suppress_deviation_count) = 0 then 0.0 else released_suppress_deviation_count * 100.00 / (released_suppress_deviation_count + (released_deviation_count - released_suppress_deviation_count)) end as suppress_percent

      from union_results
      order by is_current desc, group_name
    END_OF_QUERY
  end
  
end
