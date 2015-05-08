class OocReportDashboardSearch < SwareBase
  
  #
  # Disable calls to new from outside the class
  #
  private_class_method :new
  
  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end

#04-22-2013 merged with new query
 
  def self.search(params)
   Rails.logger.debug {"OocReportDashBoardSearch: self.search params #{params}"}  
#04-12-2013  Fix later
   $search_params_copy = params.dup

    Rails.logger.debug { "SEARCH: search_params_copy: before call to OocReportDashBoardSearch: #{$search_params_copy}" }
  
    search_params = new(params)
    
    Rails.logger.debug {"OocReportDashBoardSearch: @params #{@params}"}  

    search_params.search
  end
  
  def search

   Rails.logger.debug {"OocReportDashBoardSearch: search called"} 
   if @params[:hipresetcounts] == 1
      Rails.logger.debug {"OocReportDashBoardSearch: HipResetCounts = 1"}
   end 

    # create groups gtt
    SwareBase.connection.execute(groups_sql(true))
    # create groups index
    SwareBase.connection.execute(create_index_sql('groups', 'ooc_group_id'))
    # populate groups
    SwareBase.connection.execute(groups_sql)
    # create systems gtt
    SwareBase.connection.execute(systems_sql(true))
    # create sysetms index
    SwareBase.connection.execute(create_index_sql('systems', 'asset_id', false))
    # populate systems
    SwareBase.connection.execute(systems_sql)
    # create scans gtt
    SwareBase.connection.execute(scans_sql(true))
    # creaet scans
    SwareBase.connection.execute(create_index_sql('scans', 'asset_id', false))    
    # populate scans
    SwareBase.connection.execute(scans_sql)
    # create scan_counts gtt
    SwareBase.connection.execute(scan_counts_sql(true))
    # create scan_counts index
    SwareBase.connection.execute(create_index_sql('scan_counts', 'asset_id', false))
    # populate scan_counts
    SwareBase.connection.execute(scan_counts_sql)
    # run final query
    results = SwareBase.find_by_sql(report_sql)
    #drop tables
    ['groups', 'systems', 'scans', 'scan_counts'].each do |table_name|
      connection.execute("drop table session.#{table_name}")
    end
    return results
  end
  
  #########
  private
  #########

  attr_reader :org_l1_id, :org_id, :ooc_scan_type, :exec_dashboard_query
  
  def initialize(params)
    @params = params
    (@org_l1_id, @org_id) = params[:org_id].split(',')
    @ooc_scan_type = params[:ooc_scan_type]
    @exec_dashboard_query = @params[:exec_dashboard_query].blank?
  end


  def standard_finish_sql(table_name, sql, create_global_temp_table)
    if create_global_temp_table
      sql = "declare global temporary table #{table_name} as (
        #{sql}
        )
        definition only on commit preserve rows not logged with replace
      "
   else
      sql = "insert into session.#{table_name} (
        #{sql}
        )
      "
    end
  end

  def create_index_sql(table_name, columns, unique = true)
    return "create #{'unique' if unique} index session.#{table_name}_index on session.#{table_name} (#{columns})"
  end

  def groups_sql(create_global_temp_table = false)
    sql = <<-END_OF_QUERY
      select g.ooc_group_id, g.ooc_group_name, g.ooc_group_status
      from hip_ooc_group_v as g
      join hip_ooc_scan_type_v as gt on gt.ooc_group_type = g.ooc_group_type
      where (g.org_l1_id, g.org_id) = (#{org_l1_id}, #{org_id})
        and g.ooc_group_status in ('active', 'inactive')
        and gt.ooc_scan_type = '#{ooc_scan_type}'
      END_OF_QUERY
    return standard_finish_sql('groups', sql, create_global_temp_table)
  end

  def systems_sql(create_global_temp_table = false)
    sql = <<-END_OF_QUERY
      select a.tool_asset_vid as asset_vid, a.tool_asset_id as asset_id, g.ooc_group_id, g.ooc_group_status, a.system_status
      from dim_comm_tool_asset_hist_v as a
      left join hip_ooc_asset_group_v as ag on ag.asset_id = a.tool_asset_id
      left join session.groups as g on g.ooc_group_id = ag.ooc_group_id
      where (a.org_l1_id, a.org_id) = (#{org_l1_id}, #{org_id})
        and system_status != 'decom'
        and current_timestamp between a.row_from_timestamp and coalesce(a.row_to_timestamp, current_timestamp)
    END_OF_QUERY
    return standard_finish_sql('systems', sql, create_global_temp_table)
  end

  def scans_sql(create_global_temp_table = false)
    sql = <<-END_OF_QUERY
      with unlabeled_scans as (
      select sy.asset_id, s.scan_id, s.scan_start_timestamp, s.tool_id
      from session.systems as sy
      join dim_comm_tool_asset_scan_hist_v as s on s.asset_id = sy.asset_id
        and (s.org_l1_id, org_id) = (#{org_l1_id}, #{org_id})
        and sy.ooc_group_status = 'active'
        and s.scan_service = 'health'
      left join hip_scan_v as hs on hs.scan_id = s.scan_id
      left join hip_ooc_scan_v as os on os.scan_id = s.scan_id
      where s.scan_start_timestamp between current_timestamp - 31 days and current_timestamp
        and hs.scan_id is null
        and os.scan_id is null
      ),
      released_scans as (
      select sy.asset_id, os.scan_id, os.publish_ready_timestamp, os.scan_start_timestamp, os.tool_id
      from session.systems as sy
      join hip_ooc_scan_v as os on os.asset_id = sy.asset_id
        and sy.ooc_group_id = os.ooc_group_id
        and os.ooc_scan_type = '#{ooc_scan_type}'
        and os.appear_in_dashboard = 'y'
      where os.publish_ready_timestamp is not null
      ),
      max_publish_timestamp as (
      select asset_id, max(publish_ready_timestamp) as publish_ready_timestamp
      from released_scans
      group by asset_id
      ),
      most_recent_released_scan as (
      select rs.*
      from released_scans as rs
      join max_publish_timestamp as ms on ms.asset_id = rs.asset_id and ms.publish_ready_timestamp = rs.publish_ready_timestamp
      ),
      scans as (
      select sy.asset_id,
        case when os.scan_id is not null then 'n' when rs.asset_id is not null then 'y' else 'n' end as is_released,
        case when os.scan_id is not null then os.scan_id else rs.scan_id end as scan_id,
        case when os.scan_id is not null then os.scan_start_timestamp else rs.scan_start_timestamp end as scan_start_timestamp,
        case when os.scan_id is not null then os.tool_id else rs.tool_id end as tool_id,
        (select 'y' from unlabeled_scans as us where us.asset_id = sy.asset_id fetch first 1 row only) as are_available
      from session.systems as sy
      left join hip_ooc_scan_v as os on os.asset_id = sy.asset_id
        and os.ooc_group_id = sy.ooc_group_id
        and os.ooc_scan_type = '#{ooc_scan_type}'
        and os.publish_ready_timestamp is null
        and os.appear_in_dashboard = 'y'
      left join most_recent_released_scan as rs on rs.asset_id = sy.asset_id
      where sy.ooc_group_status = 'active'
      )
    END_OF_QUERY

    if create_global_temp_table
      sql = "declare global temporary table scans as (
        #{sql}
        select * from scans
        )
        definition only on commit preserve rows not logged with replace
      "
   else
      sql = "#{sql}
        select count(*) from final table (
          insert into session.scans (select * from scans)
        )
      "
    end
  end

  def scan_counts_sql(create_global_temp_table = false)
    sql = <<-END_OF_QUERY
      select s.asset_id, s.scan_id, count(f.finding_id) as finding_count, count(supf.finding_id) as suppressed_count
      from session.scans as s
      left join fact_scan_v as f on f.asset_id = s.asset_id
        and (f.org_l1_id, f.org_id) = (#{org_l1_id}, #{org_id})
        and f.scan_service = 'health'
        and f.severity_id = 5
        and f.scan_tool_id = s.tool_id
        and s.scan_start_timestamp between f.row_from_timestamp and coalesce(f.row_to_timestamp, current_timestamp)
      left join hip_suppress_finding_v as supf on supf.finding_id = f.finding_id
      group by s.asset_id, s.scan_id
    END_OF_QUERY
    return standard_finish_sql('scan_counts', sql, create_global_temp_table)
  end

  def report_sql
    
    unless exec_dashboard_query
      counts_select="'' as ooc_group_name,0 as ooc_group_id,"
      counts_group_by=""
    else
      counts_select="g.ooc_group_name as ooc_group_name, g.ooc_group_id,"
      counts_group_by="group by grouping sets ((g.ooc_group_name, g.ooc_group_id),())"
    end

    #
    # This is the final query.  It's the only one that is not used to creaet a global temp table.  It's a union that consists
    # of 3 parts.  The first part is the most interesting, as it creates all the stats for the active groups.
    # The second part provides counts of production and transition servers for inactive groups.  The last
    # part provides counts of production and transition servers for servers that are not part of any group of the current
    # group/scan type.
    #

    return <<-END_OF_QUERY
    with union_results as (
    -- This select is for the "active" groups and includes group totals
    select #{counts_select}
      'active' as is_current,
      count(case when sy.system_status = 'prod' then 1 else null end) as prod_count,
      count(case when sy.system_status = 'transition' then 1 else null end) as trans_count,
      --------
      count(case when s.scan_id is null and s.are_available is null and m.asset_id is null then 1 else null end) as miss_no_reason,
      count(case when s.scan_id is null and s.are_available = 'y' then 1 else null end) as none_labeled,
      count(case when s.scan_id is not null and s.is_released = 'n' then 1 else null end) as none_released, -- if a scan has been released, but another scan labeled, it will be treated as if a scan has not been released
      count(case when (s.scan_id is null and ((m.asset_id is null and s.are_available is null) or s.are_available = 'y')) or (s.scan_id is not null and s.is_released = 'n') then 1 else null end) as incomplete,
      --------
      count(case when s.is_released = 'y' then 1 else null end) as released,
      count(case when s.scan_id is null and s.are_available is null and m.asset_id is not null then 1 else null end) as miss_reason,
      count(case when s.is_released = 'y' or (s.scan_id is null and s.are_available is null and m.asset_id is not null) then 1 else null end) as complete,
      --------
      count(case when s.scan_id is not null and s.is_released = 'n' then 1 else null end) as unreleased_scan_count,
      count(case when s.scan_id is not null and s.is_released = 'n' and sc.finding_count = sc.suppressed_count then 1 else null end) as unreleased_no_valid_deviations_scan_count,
      count(case when s.scan_id is not null and s.is_released = 'n' and sc.finding_count - sc.suppressed_count > 0 then 1 else null end) as unreleased_unvalidated_scans_count,
      sum(case when s.scan_id is not null and s.is_released = 'n' then sc.finding_count - sc.suppressed_count else 0 end) as unreleased_valid_deviation_count,
      sum(case when s.scan_id is not null and s.is_released = 'n' then sc.suppressed_count else 0 end) as unreleased_suppress_deviation_count,
      --------
      count(case when s.scan_id is not null and s.is_released = 'y' then 1 else null end) as released_scan_count,
      count(case when s.scan_id is not null and s.is_released = 'y' and sc.finding_count = sc.suppressed_count then 1 else null end) as released_no_valid_deviations_scan_count,
      count(case when s.scan_id is not null and s.is_released = 'y' and sc.finding_count - sc.suppressed_count > 0 then 1 else null end) as released_scan_valid_count,
      sum(case when s.scan_id is not null and s.is_released = 'y' then sc.finding_count - sc.suppressed_count else 0 end) as released_valid_deviation_count,
      sum(case when s.scan_id is not null and s.is_released = 'y' then sc.suppressed_count else 0 end) as released_suppress_deviation_count,
      avg(case when s.scan_id is not null and s.is_released = 'y' then sc.finding_count - sc.suppressed_count else 0 end) as valid_deviations_avg
    from session.groups as g
    left join session.systems as sy on g.ooc_group_id = sy.ooc_group_id
    left join session.scans as s on s.asset_id = sy.asset_id
    left join session.scan_counts as sc on sc.scan_id = s.scan_id
    left join hip_ooc_missed_scan_v as m on m.ooc_group_id = g.ooc_group_id
      and m.ooc_scan_type = '#{ooc_scan_type}'
      and m.asset_id = sy.asset_id
    where g.ooc_group_status = 'active'
    #{counts_group_by}
    union
      -- This select is for the inactive groups, and includes an inactive groups total
      select g.ooc_group_name,
        g.ooc_group_id,
        'inactive' as is_current,
        count(case when sy.system_status = 'prod' then 1 else null end) as prod_count,
        count(case when sy.system_status = 'transition' then 1 else null end) as trans_count,
        cast(null as integer) as miss_no_reason,
        cast(null as integer) as none_labeled,
        cast(null as integer) as none_released,
        cast(null as integer) as incomplete,
        cast(null as integer) as released,
        cast(null as integer) as miss_reason,
        cast(null as integer) as complete,
        cast(null as integer) as unreleased_scan_count,
        cast(null as integer) as unreleased_no_valid_deviations_scan_count,
        cast(null as integer) as unreleased_unvalidated_scans_count,
        cast(null as integer) as unreleased_valid_deviation_count,
        cast(null as integer) as unreleased_suppress_deviation_count,
        cast(null as integer) as released_scan_count,
        cast(null as integer) as released_suppress_deviation_count,
        cast(null as integer) as released_valid_deviation_count,
        cast(null as integer) as released_scan_valid_count,
        cast(null as integer) as released_no_valid_deviations_scan_count,
        cast(null as integer) as valid_deviations_avg
    from session.groups as g
    join session.systems as sy on sy.ooc_group_id = g.ooc_group_id
    where g.ooc_group_status = 'inactive'
    group by grouping sets ((g.ooc_group_name, g.ooc_group_id), ())
    union
      -- This select is for the unassigend systems, and includes a total
      select cast(null as varchar(1)) as ooc_group_name,
        cast(null as integer) as ooc_group_id,
        cast(null as char(1)) as is_current,
        count(case when sy.system_status = 'prod' then 1 else null end) as prod_count,
        count(case when sy.system_status = 'transition' then 1 else null end) as trans_count,
        cast(null as integer) as miss_no_reason,
        cast(null as integer) as none_labeled,
        cast(null as integer) as none_released,
        cast(null as integer) as incomplete,
        cast(null as integer) as released,
        cast(null as integer) as miss_reason,
        cast(null as integer) as complete,
        cast(null as integer) as unreleased_scan_count,
        cast(null as integer) as unreleased_no_valid_deviations_scan_count,
        cast(null as integer) as unreleased_unvalidated_scans_count,
        cast(null as integer) as unreleased_valid_deviation_count,
        cast(null as integer) as unreleased_suppress_deviation_count,
        cast(null as integer) as released_scan_count,
        cast(null as integer) as released_suppress_deviation_count,
        cast(null as integer) as released_valid_deviation_count,
        cast(null as integer) as released_scan_valid_count,
        cast(null as integer) as released_no_valid_deviations_scan_count,
        cast(null as integer) as valid_deviations_avg
      from session.systems as sy
      where sy.ooc_group_id is null
    )
    select
    ooc_group_name,
    ooc_group_id,
    is_current,
    prod_count,
    trans_count,
    miss_no_reason,
    none_labeled,
    none_released,
    incomplete,
    released,
    miss_reason,
    complete,
    unreleased_scan_count,
    unreleased_no_valid_deviations_scan_count,
    unreleased_unvalidated_scans_count,
    unreleased_valid_deviation_count,
    unreleased_suppress_deviation_count,
    released_scan_count,
    released_suppress_deviation_count,
    released_valid_deviation_count,
    released_scan_valid_count,
    released_no_valid_deviations_scan_count,
    valid_deviations_avg,
    released_suppress_deviation_count + released_valid_deviation_count as released_total_valid_deviation_count,
    case when (released_suppress_deviation_count + released_valid_deviation_count) = 0 then 0.0 else released_suppress_deviation_count * 100.00 / (released_suppress_deviation_count + released_valid_deviation_count) end as suppress_percent
    from union_results
    order by is_current desc, ooc_group_name
    END_OF_QUERY
  end
  
end
