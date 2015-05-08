class PublishScanSearch

  attr_accessor :os,:hc_group_id, :scan_type,:publish_status,
    :page,:per_page,:org_id,:val_status,:host_name,:ip_address

   # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end

 # query for a list of assets
  def self.search(params)
    @hc_group_id=params['hc_group_id']
    @val_status=params['val_status']
    @scan_type=params['scan_type']
    @org_id=params['org_id']
    @os=params['os']
    @ip_address=params['ip_address']
    @host_name=params['host_name']
    @publish_status=params['publish_status']
    find_scans
  end
  
  private

  # query for paination for review
  def self.find_scans
    AssetScan.find_by_sql sql() #, :page => @page, :per_page=>@per_page
  end

  def self.sql
    (l1id,id)=@org_id.split(',')
    sql = "with assets as (
    -- This first query searches for the assets that we limit scans to.
    select asst.asset_id,
      asst.asset_vid
    from hip_hc_group_v as hgrp
    join hip_asset_group_v as agrp on agrp.hc_group_id = hgrp.hc_group_id
    join dim_scan_asset_period_v as asst on asst.asset_id = agrp.asset_id
      and asst.period_month_id = #{SwareBase.current_month_period_id}
    where hgrp.org_l1_id = #{l1id}
    and hgrp.org_id = #{id}
    and hgrp.is_current = 'y'
    and asst.system_status = 'prod'
    -- And additional search filters releated to assets should go here
    #{"and " unless conditions("host").blank?}#{conditions("host").join('')}
    ),
    recent_scans as (
    -- This query looks at the hip tables to find scans within the recent past
    select scan.asset_id, scan.scan_id
    from dim_comm_tool_asset_scan_hist_v as scan
    join assets as asst on asst.asset_id = scan.asset_id
    join hip_scan_v as hscan on hscan.scan_id = scan.scan_id
      and hscan.period_id = #{SwareBase.current_period_id}
    where scan.scan_service = 'health'
    and scan.org_l1_id = #{l1id}
    and scan.org_id = #{id}
    and hscan.lu_timestamp > current_timestamp - 1 hour
    -- To filter on scan attributes, add conditions here, and on the older_scans query below
    ),
    older_scans as (
    -- This query looks at the summary tables to find scans older than the recent past
    select asst.asset_id, scan.scan_id
    from dim_scan_scan_period_v as scan
    join assets as a on a.asset_vid = scan.asset_vid
    join dim_scan_asset_period_v as asst on asst.asset_vid = scan.asset_vid
    where scan.period_month_id = #{SwareBase.current_month_period_id}
      and scan.org_l1_id = #{l1id}
      and scan.org_id = #{id}
    	-- To filter on scan attributes, add conditions here, and on the recent_scans query above
    ),
    -- This query combines the recent and older scans and eliminates duplicates rows
    all_scans as (
    select asset_id, scan_id from recent_scans
    union
    select asset_id, scan_id from older_scans
    ),
    -- This query limites the scans to one per asset.  A unreleased scan sill be selected first.  
    -- Otherwise the most recently released scan will be used
    --
    -- Note, if you wanted to find all the scans, this query could be removed, or alternatively
    -- it could be replaced by 'latest_scans as (select * from all_scans)'
    latest_scans as (
    select all.asset_id, all.scan_id
    from all_scans as all
    join dim_comm_tool_asset_scan_hist_v as scan on scan.scan_id = all.scan_id
    join hip_scan_v as hscan on hscan.scan_id = all.scan_id
    where coalesce(publish_ready_timestamp, '9999-12-31 00:00:00.0')
      = (select coalesce(publish_ready_timestamp, '9999-12-31 00:00:00.0') 
        from hip_scan_v as h
        join dim_comm_tool_asset_scan_hist_v as s on s.scan_id = h.scan_id
        where period_id = #{SwareBase.current_period_id} 
          and s.asset_id = all.asset_id
        order by (coalesce(publish_ready_timestamp, '9999-12-31 00:00:00.0')) desc
        fetch first 1 row only)
    ),
    -- This query get the suppressed finding list currently active
    suppressed as (
    select finding_id
    from hip_suppress_v as supp
    join hip_suppress_finding_v as suppf on suppf.suppress_id = supp.suppress_id
    where supp.org_l1_id = #{l1id}
    and org_id = #{id}
    and current_timestamp between supp.start_timestamp and supp.end_timestamp
    ),
    summary as (
    -- This query pulls it all together, looks for the deviations, and does the summary
    select s.scan_id,
      asst.host_name,
      asst.ip_string_list,
    	count(case when s.scan_id is not null and fact.finding_id is not null then 1 else null end) as deviation_count,
      scan.scan_start_timestamp,
      hscan.scan_type,
      asst.os_product,
      asst.hc_group_name as group_name,
      asst.hc_group_id,
    	count(case when s.scan_id is not null and fact.finding_id is null then 1 else null end) as clean,
    	count(case when fact.finding_id is not null and supp.finding_id is null then 1 else null end) as valid,
    	count(case when fact.finding_id is not null and supp.finding_id is not null then 1 else null end) as suppressed,
      hscan.publish_ready_timestamp
    from dim_scan_asset_period_v as asst
    join assets as a on a.asset_vid = asst.asset_vid
      and asst.period_month_id = #{SwareBase.current_month_period_id}
    --left join latest_scans as s on s.asset_id = a.asset_id
    join latest_scans as s on s.asset_id = a.asset_id
    left join dim_comm_tool_asset_scan_hist_v as scan on scan.scan_id = s.scan_id
    left join hip_scan_v as hscan on hscan.scan_id = s.scan_id
    left join fact_scan_v as fact on fact.asset_id = s.asset_id
      and fact.org_l1_id = scan.org_l1_id
      and fact.org_id = scan.org_id
      and fact.scan_service = 'health'
      and fact.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})
      and scan.scan_start_timestamp between fact.row_from_timestamp and coalesce(fact.row_to_timestamp, current_timestamp)
      and fact.severity_id=5
      and fact.scan_tool_id = scan.tool_id
    left join suppressed as supp on supp.finding_id = fact.finding_id
    group by s.scan_id,
      asst.host_name,
      asst.ip_string_list,
      scan.scan_start_timestamp,
      hscan.scan_type,
      asst.os_product,
      asst.hc_group_name,
      asst.hc_group_id,
      hscan.publish_ready_timestamp
    )
    select * from summary
    -- Add a where clause here to filter based on the results
    #{"where " unless conditions("group").blank?}#{conditions("group").join('')}
    order by host_name, scan_start_timestamp, scan_type
    "
  end

  def self.hc_group_id_host_conditions
    if @hc_group_id.downcase!='all'
      ["hgrp.hc_group_id = #{@hc_group_id}",nil]
    end
  end

  def self.val_status_group_conditions
    case @val_status
    when "none"
      ["unvalidated = 0",nil]
    when "some"
      ["unvalidated > 0",nil]
    when "clean"
      ["clean > 0",nil]
    end
  end

  def self.publish_status_group_conditions
    case @publish_status
    when "published"
      ["publish_ready_timestamp is not null",nil]
    when "not_published"
      ["publish_ready_timestamp is null",nil]
    end
  end

  def self.scantype_group_conditions
    if (@scan_type!='all' and @scan_type!='unlabeled')
      return ["scan_type = '#{@scan_type}'",nil]
    end
    if @scan_type=='unlabeled'
      return ["scan_type is null",nil]
    end
  end

  def self.date_range_group_conditions
    ["CAST(scan_start_timestamp AS date) BETWEEN '#{@start_date}' AND '#{@end_date}'",nil] unless @start_date.blank? and @end_date.blank?
  end

  def self.ip_address_host_conditions
    ["asst.ip_string_list like '%#{@ip_address.strip}%'",nil] unless @ip_address.blank?
  end
  
  def self.host_name_host_conditions
    [" lower(asst.host_name) like '%#{@host_name.downcase.strip}%'",nil] unless @host_name.blank?
  end

  def self.os_host_conditions
    ["asst.os_product = '#{@os}' ",nil] unless @os.downcase=='all'
  end

  def self.conditions(type)
    unless conditions_options(type).blank?
      [conditions_clauses(type).join(' AND '), *conditions_options(type)] 
    else
      []
    end
  end

  def self.conditions_clauses(type)
    conditions_parts(type).map { |condition|  condition.first }
  end

  def self.conditions_options(type)
    conditions_parts(type).map { |condition| condition[1..-1] }.flatten
  end

  def self.conditions_parts(type)
    self.methods.grep(/#{type}_conditions$/).map { |m| send(m) }.compact
  end

  def self.limit_part(n = 1)
    if SwareBase.db2?
      "fetch first #{n} row only"
    else
      "limit #{n}"
    end
  end

  def self.standardize_date(date_in)
    return date_in if date_in.empty?
    date = date_in.split('/')
    date_out = "#{date[2]}-#{date[0]}-#{date[1]}"
    return date_out
  end

end
