class OocReleaseScanSearch 

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
    @params[:org_id].split(',')[0]
  end

  def org_id
    @params[:org_id].split(',')[1]
  end

  def sql
    "with assets as (
        -- This first query searches for the assets that we limit scans to.
        select asst.tool_asset_id,
          asst.tool_asset_vid,hgrp.ooc_group_id
        from hip_ooc_group_v as hgrp
        join hip_ooc_asset_group_v as agrp on agrp.ooc_group_id = hgrp.ooc_group_id
        join  dim_comm_tool_asset_hist_v as asst on asst.tool_asset_id = agrp.asset_id
          and current_timestamp between asst.row_from_timestamp and coalesce(asst.row_to_timestamp,current_timestamp)
        where hgrp.org_l1_id = #{org_l1_id}
        and hgrp.org_id = #{org_id}
        and hgrp.ooc_group_id=#{@params[:ooc_group_id]}
        and hgrp.ooc_group_type !='deleted'
        and asst.system_status != 'decom'
        -- And additional search filters releated to assets should go here
        ),
        recent_scans as (
        -- This query looks at the hip tables to find scans within the recent past
        select scan.asset_id, scan.scan_id
        from dim_comm_tool_asset_scan_hist_v as scan
        join assets as asst on asst.tool_asset_id = scan.asset_id
        join hip_ooc_scan_v as hscan on hscan.scan_id = scan.scan_id
          and hscan.appear_in_dashboard = 'y'
        where scan.scan_service = 'health'
        and scan.org_l1_id = #{org_l1_id}
        and scan.org_id = #{org_id}
        and asst.ooc_group_id=#{@params[:ooc_group_id]}
        and hscan.ooc_scan_type='#{@params[:ooc_scan_type]}'

        -- To filter on scan attributes, add conditions here, and on the older_scans query below
        ),
        latest_scans as (
        select all.asset_id, all.scan_id
        from recent_scans as all
        join dim_comm_tool_asset_scan_hist_v as scan on scan.scan_id = all.scan_id
        join hip_ooc_scan_v as hscan on hscan.scan_id = all.scan_id
          and hscan.ooc_group_id=#{@params[:ooc_group_id]} and hscan.ooc_scan_type='#{@params[:ooc_scan_type]}'
          and hscan.appear_in_dashboard = 'y'
        where coalesce(hscan.publish_ready_timestamp, '9999-12-31 00:00:00.0')
          = (select coalesce(hscan.publish_ready_timestamp, '9999-12-31 00:00:00.0')
            from hip_ooc_scan_v as h
            join dim_comm_tool_asset_scan_hist_v as s on s.scan_id = h.scan_id
            where s.asset_id = all.asset_id
            and hscan.ooc_group_id=#{@params[:ooc_group_id]} and hscan.ooc_scan_type='#{@params[:ooc_scan_type]}'
            and hscan.appear_in_dashboard = 'y'
            order by (coalesce(hscan.publish_ready_timestamp, '9999-12-31 00:00:00.0')) desc
            fetch first 1 row only)
        ),
        -- This query get the suppressed finding list currently active
        suppressed as (
        select finding_id
        from hip_suppress_v as supp
        join hip_suppress_finding_v as suppf on suppf.suppress_id = supp.suppress_id
        where supp.org_l1_id = #{org_l1_id}
        and org_id = #{org_id}
        and current_timestamp between supp.start_timestamp and supp.end_timestamp
        ),        
        summary as (
        -- This query pulls it all together, looks for the deviations, and does the summary
        select s.scan_id,
          asst.host_name,
          asst.system_status,
          asst.ip_string_list,
          scan.scan_start_timestamp,
          hscan.ooc_scan_type,
          os.os_product,
          grp.ooc_group_name,
          grp.ooc_group_id,
          grp.ooc_group_type,
          hscan.publish_ready_timestamp,
          count(case when s.scan_id is not null and fact.finding_id is not null then 1 else null end) as deviation_count,
          count(case when s.scan_id is not null and fact.finding_id is null then 1 else null end) as clean,
          count(case when fact.finding_id is not null and supp.finding_id is null then 1 else null end) as count_valid,
          0 as count_unvalidated,
          count(case when fact.finding_id is not null and supp.finding_id is not null then 1 else null end) as count_suppressed
        from dim_comm_tool_asset_hist_v as asst
        join assets as a on a.tool_asset_id = asst.tool_asset_id
        join dim_comm_os_v as os on os.os_id=asst.os_id
        join hip_ooc_group_v as grp on grp.ooc_group_id=a.ooc_group_id
        left join latest_scans as s on s.asset_id = a.tool_asset_id
        left join dim_comm_tool_asset_scan_hist_v as scan on scan.scan_id = s.scan_id
        left join hip_ooc_scan_v as hscan on hscan.scan_id = s.scan_id
          and hscan.appear_in_dashboard = 'y'
        left join fact_scan_v as fact on fact.asset_id = s.asset_id
          and fact.org_l1_id = scan.org_l1_id
          and fact.org_id = scan.org_id
          and fact.scan_service = 'health'
          and fact.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})
          and scan.scan_start_timestamp between fact.row_from_timestamp and coalesce(fact.row_to_timestamp, current_timestamp)
          and fact.severity_id=5
          and fact.scan_tool_id = scan.tool_id
        left join suppressed as supp on supp.finding_id = fact.finding_id
        where  current_timestamp between asst.row_from_timestamp and coalesce(asst.row_to_timestamp,current_timestamp)
        group by s.scan_id,
          asst.host_name,
          asst.system_status,
          asst.ip_string_list,
          scan.scan_start_timestamp,
          hscan.ooc_scan_type,
          os.os_product,
          grp.ooc_group_name,
          grp.ooc_group_id,
          grp.ooc_group_type,
          hscan.publish_ready_timestamp
        )
        select * from summary
        WHERE
        #{conditions}
        and system_status!='decom'
        order by host_name"
  end


  def org_conditions
    # ["ah.org_l1_id=#{org_l1_id} AND ah.org_id=#{org_id}",nil]
  end

  def group_type_conditions
    ["ooc_group_type = '#{@params[:ooc_group_type]}'",nil]
  end

  def ooc_group_id_conditions
    ["ooc_group_id = #{@params[:ooc_group_id]}"]
  end

  def system_status_conditions
    ["system_status = '#{@params[:system_status]}'"] unless @params[:system_status].blank?
  end

  def os_product_conditions
    ["os_product = '#{@params[:os_product]}'"] unless @params[:os_product].blank?
  end

  def host_name_conditions
    ["lower(host_name) LIKE '%#{@params[:host_name].downcase.strip}%'",] unless @params[:host_name].blank?
  end

  def ip_string_list_conditions
    ["ip_string_list LIKE '%#{@params[:ip_address].strip}%'"] unless @params[:ip_address].blank?
  end

  def val_status_conditions
    case @params[:val_status]
    when "none"
      ["count_unvalidated = 0",nil]
    when "some"
      ["count_unvalidated > 0",nil]
    when "clean"
      ["clean > 0"]
    end
  end

  def publish_status_conditions
    case @params[:publish_status]
    when "published"
      ["publish_ready_timestamp is not null",nil]
    when "not_published"
      ["publish_ready_timestamp is null",nil]
    end
  end

  def scantype_conditions
    ["ooc_scan_type = '#{@params[:ooc_scan_type]}'"]
  end

  def date_range_conditions
    # ["CAST(scan_start_timestamp AS date) BETWEEN '#{@start_date}' AND '#{@end_date}'",nil] unless @start_date.blank? and @end_date.blank?
  end

  def conditions
    [conditions_clauses.join(' AND '), *conditions_options].join('') unless conditions_options.blank?
  end

  def conditions_clauses
    conditions_parts.map { |condition|  condition.first }
  end

  def conditions_options
    conditions_parts.map { |condition| condition[1..-1] }.flatten
  end

  def conditions_parts
    self.private_methods.grep(/_conditions$/).map { |m| send(m) }.compact
  end

  def limit_part(n = 1)
    if SwareBase.db2?
      "fetch first #{n} row only"
    else
      "limit #{n}"
    end
  end

  def standardize_date(date_in)
    return date_in if date_in.empty?
    date = date_in.split('/')
    date_out = "#{date[2]}-#{date[0]}-#{date[1]}"
    return date_out
  end

end
