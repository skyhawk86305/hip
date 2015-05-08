class OocScanSearch
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


  def self.inventory_scan_status(params)
    search_params = new(params)
    search_params.inventory_scan_status
  end

  def inventory_scan_status
    result = SwareBase.find_by_sql(sql_inventory_scan_status)
    return result
  end

  def self.scan_count(params)
    search_params = new(params)
    search_params.scan_count
  end
  
  def scan_count
    return get_scan_count()
  end

  def self.latest_scan(params)
    search_params = new(params)
    search_params.latest_scan
  end

  def latest_scan
    result = SwareBase.find_by_sql(sql_latest_scan)
    return result
  end
  #########
  private
  #########

  def initialize(params)
    @params = params

#05-15-2013 
    if @params[:ooc_group_id].kind_of?(Array)
       @group_id_list = @params[:ooc_group_id].map {|group_id| group_id.to_i}
    else
      @group_id_list = [@params[:ooc_group_id].to_i]
    end

    @group_id_list_str = @group_id_list.map{ |i| %Q('#{i}') }.join(',')

  end

  def org_l1_id
    @params[:org_id].split(',')[0]
  end

  def org_id
    @params[:org_id].split(',')[1]
  end

  def sql
    #if @params.nil?
    start_date = ''
    end_date = ''
    #else
    start_date = standardize_date(@params[:start_date]) unless @params[:start_date].blank?
    end_date = standardize_date(@params[:end_date]) unless @params[:end_date].blank?
    #end
    if start_date.empty? && end_date.empty?
      date_limit = "and date(scan.scan_start_timestamp) between current_date - 31 days and current_date"
    else
      date_limit = "and date(scan.scan_start_timestamp) between '#{start_date}' and '#{end_date}'"
    end

    "with system_and_scan_type as (
        select
          group.ooc_group_id,
          type.ooc_scan_type,
          asst.tool_asset_id as asset_id,
          asst.host_name,
          os.os_product,
          group.ooc_group_name,
          asst.ip_string_list
        from hip_ooc_scan_type_v as type
        join hip_ooc_group_v as group on group.ooc_group_type = type.ooc_group_type and ooc_group_status = 'active'
        join hip_ooc_asset_group_v as assg on assg.ooc_group_id = group.ooc_group_id
        join dim_comm_tool_asset_hist_v as asst on asst.tool_asset_id = assg.asset_id
          and asst.org_l1_id = group.org_l1_id
          and asst.org_id = group.org_id
          and current_timestamp between asst.row_from_timestamp and coalesce(asst.row_to_timestamp, current_timestamp)
          and asst.system_status != 'decom'    
        join dim_comm_os_v as os on os.os_id = asst.os_id
        where group.ooc_group_id in (#{@group_id_list_str})
          and type.ooc_scan_type = '#{@params[:ooc_scan_type]}'
          and group.org_l1_id = #{org_l1_id}
          and group.org_id = #{org_id}
          #{#"-- insert other system filter parameters here"
           }
          #{system_status_conditions}
          #{host_name_conditions}
          #{ip_address_conditions}
          #{os_conditions}
          #{hc_required_conditions}
          #{hc_sec_class_conditions}
          ),
      eligible_scans as (
      -- here we want to produce a list of scans that are available to be used -- either not labeled, or labled for the current group
      -- if unlabled, we only want scans from the last 30 days
      select scan.*								-- scans that are not labeled and in the last 30 days -- eligible scans
      from system_and_scan_type as sst
      join dim_comm_tool_asset_scan_hist_v as scan on scan.asset_id = sst.asset_id
      and scan.scan_service = 'health'
      #{date_limit}
      left join hip_scan_v as hcscan on hcscan.scan_id = scan.scan_id
      left join hip_ooc_scan_v as oocscan on oocscan.scan_id = scan.scan_id
      where hcscan.scan_id is null
      and oocscan.scan_id is null
      union
      select scan.*								-- scans that are labeled for this ooc_group/ooc_scan_type
      from system_and_scan_type as sst
      join hip_ooc_scan_v as oocscan on oocscan.asset_id = sst.asset_id
      and oocscan.ooc_group_id = sst.ooc_group_id
      and oocscan.ooc_scan_type = sst.ooc_scan_type
      and oocscan.appear_in_dashboard = 'y'
      join dim_comm_tool_asset_scan_hist_v as scan on scan.scan_id = oocscan.scan_id
     ),
      scans as (#{#
    #-- The following query will return at least one row for each system  There may be more rows if ther are
    #-- multiple labeled scans for the specified scan type.  If there are multiple labeled scans, only one of
    #-- them can be un released
    #-- Rules:	1) If a scan has been labeled, the missing reason (if it has one) is meaningless
    #--				2) The scan_id returned is the scan_id of the labeled and not released scan
          }
        select
          sst.ooc_group_id,
          sst.ooc_scan_type as scan_type,
          sst.asset_id,
          sst.host_name,
          sst.os_product,
          sst.ooc_group_name,
          sst.ip_string_list,
          tool.manager_name,
          tool.tool_id,
          scan.scan_id,
          hscan.scan_id as labeled_scan_id,
          hscan.publish_ready_timestamp,
          missed.ooc_missed_scan_id,
          case when hscan.publish_ready_timestamp is not null then 'y'
            else 'n'
            end as released
        from system_and_scan_type as sst
        left join eligible_scans as scan on scan.asset_id = sst.asset_id
        left join hip_ooc_scan_v as hscan on hscan.scan_id = scan.scan_id
          and hscan.ooc_scan_type = sst.ooc_scan_type
          and hscan.ooc_group_id = sst.ooc_group_id
          and hscan.appear_in_dashboard = 'y'
        left join dim_comm_tool_v as tool on tool.tool_id=scan.tool_id
        left join hip_ooc_missed_scan_v as missed on missed.ooc_group_id = sst.ooc_group_id
          and missed.ooc_scan_type = sst.ooc_scan_type
          and missed.asset_id = sst.asset_id

          #{"WHERE "+scan_tool_conditions unless @params[:scan_tool_id].blank?}
      ),
      #{#"--
    #-- This query counts various attributes of the scans which are used by the next query to determine various
    #-- system scan attributes
    #--"
        }
      scan_counts as (
        select
          s.ooc_group_id,
          s.asset_id,
          s.host_name,
          s.os_product,
          s.ooc_group_name,
          s.ip_string_list,
          s.scan_type,
          max(s.publish_ready_timestamp) publish_ready_timestamp,
          count(case when s.labeled_scan_id is not null then 1 else null end) as labeled_scan_count,
          max(case when s.labeled_scan_id is not null and released = 'n' then s.labeled_scan_id else null end) as scan_id,
          count(case when s.scan_id is null and s.ooc_missed_scan_id is not null then 1 else null end) as missed_with_reason_count,
          count(case when s.scan_id is not null then 1 else null end) as scan_count,
          count(case when released = 'y' then 1 else null end) as released_scan_count,
          #{#"-- change the cast statment below to 'count(case when ... then 1 else null end)' to count some condiction -- usually
    #-- to count some particular condictions of a scan"
            }
          cast(null as integer) as condiction_count
        from scans as s
        group by s.ooc_group_id, s.asset_id, s.host_name, s.os_product, s.ooc_group_name, s.ip_string_list, s.scan_type
      ),
      #{#"--
    #-- The following query uses the counts to caculate the scan_type (with the additional values of 'Missing' and 'Unlabeled')
    #-- and the system_scan_status.
    #--"
      }
      system_status as (
        select
          sc.ooc_group_id,
          sc.asset_id,
          sc.host_name,
          sc.os_product,
          sc.ooc_group_name as group_name,
          sc.ip_string_list,
          sc.scan_count,
          sc.labeled_scan_count,
          sc.missed_with_reason_count,
          sc.released_scan_count,
          sc.condiction_count,
          sc.scan_id,
          sc.publish_ready_timestamp,
          case when sc.scan_count = 0 then ''
            when sc.labeled_scan_count = 0 then 'Unlabeled'
            when sc.labeled_scan_count > sc.released_scan_count then sc.scan_type
            else ''
          end as scan_type,
          case
            when sc.scan_count = 0 and sc.missed_with_reason_count = 0 then 'Scan Not Available'
            when sc.scan_count = 0 and sc.missed_with_reason_count != 0 then 'Missing, reason provided'
            when sc.labeled_scan_count = 0 then 'Available, none labeled'
            when sc.released_scan_count = 0 then 'Labeled, none released'
            else 'Released'
          end as system_scan_status
          from scan_counts as sc
      )
      #{#"--
    #-- The final select.  Used to filter the results
    #--"
        }
      select * from system_status
      #{#"-- Insert where clause here to filter by counts or computed values#
        }
      WHERE 1=1
      #{system_scan_status_condition}
      #{release_date_conditions}
      #{can_be_labeled_conditions}
      order by group_name, host_name"
  end

  def sql_inventory_scan_status
    #if @params.nil?
    start_date = ''
    end_date = ''
    #else
    start_date = standardize_date(@params[:start_date]) unless @params[:start_date].blank?
    end_date = standardize_date(@params[:end_date]) unless @params[:end_date].blank?
    #end
    if start_date.empty? && end_date.empty?
      date_limit = "and date(scan.scan_start_timestamp) between current_date - 31 days and current_date"
    else
      date_limit = "and date(scan.scan_start_timestamp) between #{SwareBase.quote_value(start_date)} and #{SwareBase.quote_value(end_date)}"
    end

    ooc_scan_type = @params[:ooc_scan_type]
    ooc_group_type = @params[:ooc_group_type]

    return "
    -- return all systems in inventory
    with system_and_scan_type as (
      select
        asst.tool_asset_id as asset_id,
        group.ooc_group_type,
        group.ooc_group_id,
        group.org_l1_id,
        group.org_id
      from dim_comm_tool_asset_hist_v as asst
      left join hip_ooc_asset_group_v as assg on assg.asset_id = asst.tool_asset_id
      left join hip_ooc_group_v as group on group.ooc_group_id = assg.ooc_group_id
        and group.ooc_group_type = #{SwareBase.quote_value(ooc_group_type)}
        and group.org_l1_id = #{org_l1_id} and group.org_id= #{org_id}
      where
        asst.system_status != 'decom'
        and asst.org_l1_id = #{org_l1_id} and asst.org_id = #{org_id}
        and current_timestamp between asst.row_from_timestamp and coalesce(asst.row_to_timestamp, current_timestamp)
    ),
    eligible_scans as (
      -- here we want to produce a list of scans that are available to be used -- either not labeled, or labled for the current group
      -- if unlabled, we only want scans from the last 30 days
      -- scans that are not labeled and in the last 30 days -- eligible scans
      select scan.*, oocscan.ooc_scan_type
      from system_and_scan_type as sst
      join dim_comm_tool_asset_scan_hist_v as scan on scan.asset_id = sst.asset_id
        and scan.scan_service = 'health'
        #{date_limit}
        and (scan.org_l1_id, scan.org_id) = (sst.org_l1_id, sst.org_id)
      left join hip_scan_v as hcscan on hcscan.scan_id = scan.scan_id
      left join hip_ooc_scan_v as oocscan on oocscan.scan_id = scan.scan_id
      where hcscan.scan_id is null and oocscan.scan_id is null
      union
      -- scans that are labeled for this ooc_group/ooc_scan_type
      select scan.*, oocscan.ooc_scan_type
      from system_and_scan_type as sst
      join hip_ooc_scan_v as oocscan on oocscan.asset_id = sst.asset_id
        and oocscan.ooc_group_id = sst.ooc_group_id
        and oocscan.ooc_scan_type = #{SwareBase.quote_value(ooc_scan_type)}
        and oocscan.appear_in_dashboard = 'y'
      join dim_comm_tool_asset_scan_hist_v as scan on scan.scan_id = oocscan.scan_id
    ) ,
    scans as (
      select
        sst.asset_id,
        sst.ooc_group_type,
        sst.ooc_group_id,
        scan.ooc_scan_type as scan_type,
        scan.scan_id,
        hscan.scan_id as labeled_scan_id,
        hscan.publish_ready_timestamp,
        missed.ooc_missed_scan_id,
        msr.missed_scan_reason,
        case when hscan.publish_ready_timestamp is not null then 'y' else 'n' end as released
      from system_and_scan_type as sst
      left join eligible_scans as scan on scan.asset_id = sst.asset_id
      left join hip_ooc_scan_v as hscan on hscan.scan_id = scan.scan_id
        and hscan.ooc_scan_type = #{SwareBase.quote_value(ooc_scan_type)}
        and hscan.ooc_group_id = sst.ooc_group_id
        and hscan.appear_in_dashboard = 'y'
      left join hip_ooc_missed_scan_v as missed on missed.ooc_group_id = sst.ooc_group_id
        and missed.ooc_scan_type = hscan.ooc_scan_type
        and missed.asset_id = sst.asset_id
      left join hip_missed_scan_reason_v as msr on msr.missed_scan_reason_id = missed.ooc_missed_scan_id
      where sst.ooc_group_id is not null -- exclude scans that are not part of a group
    ),
    scan_counts as (
      select
        s.asset_id,
        s.ooc_group_type,
        s.ooc_group_id,
        max(s.scan_type) scan_type,
        max(s.publish_ready_timestamp) publish_ready_timestamp,
        max(s.ooc_missed_scan_id) ooc_missed_scan_id,
        count(case when s.labeled_scan_id is not null then 1 else null end) as labeled_scan_count,
        max(case when s.labeled_scan_id is not null and released = 'n' then s.labeled_scan_id else null end) as scan_id,
        count(case when s.scan_id is null and s.ooc_missed_scan_id is not null then 1 else null end) as missed_with_reason_count,
        count(case when s.scan_id is not null then 1 else null end) as scan_count,
        count(case when released = 'y' then 1 else null end) as released_scan_count,
        cast(null as integer) as condiction_count
      from scans as s
      group by s.asset_id, s.ooc_group_type, s.ooc_group_id
    ),
    system_status as (
      select
        sc.asset_id,
        ah.host_name,
        ah.ip_string_list,
        ah.hc_start_date,
        ah.security_policy_name,
        ah.system_status,
        ah.hc_auto_interval_weeks,
        ah.hc_manual_interval_weeks,
        ah.hc_manual_flag,
        ah.hc_auto_flag,
        os.os_product,
        CASE
          WHEN ah.hc_auto_flag='y' and ah.hc_manual_flag='y' then 'Yes'
          WHEN ah.hc_auto_flag='n' and ah.hc_manual_flag='n' then 'No'
         ELSE NULL
         END AS hc_required,
        g.ooc_group_name,
        g.ooc_group_status,
        g.ooc_group_type,
        g.ooc_group_id,
        msr.missed_scan_reason,
        sc.scan_count,
        sc.labeled_scan_count,
        sc.missed_with_reason_count,
        sc.released_scan_count,
        sc.condiction_count,
        sc.scan_id,
        sc.publish_ready_timestamp,
        case
          when sc.scan_count = 0 then ''
          when sc.labeled_scan_count = 0 then 'Unlabeled'
          else sc.scan_type
          end as scan_type,
        case
          when sc.scan_count = 0 and sc.missed_with_reason_count = 0 then 'Scan Not Available'
          when sc.scan_count = 0 and sc.missed_with_reason_count != 0 then 'Missing, reason provided'
          when sc.labeled_scan_count = 0 then 'Available, none labeled'
          when sc.released_scan_count = 0 then 'Labeled, none released'
          else 'Released'
          end as system_scan_status,
        tool.manager_name
      from scan_counts as sc
      left join hip_ooc_missed_scan_v as ooc_ms on ooc_ms.ooc_missed_scan_id=sc.ooc_missed_scan_id
      left join hip_missed_scan_reason_v as msr on msr.missed_scan_reason_id=ooc_ms.missed_scan_reason_id
      join dim_comm_tool_asset_hist_v as ah on ah.tool_asset_id=sc.asset_id
        and current_timestamp between ah.row_from_timestamp and coalesce(ah.row_to_timestamp, current_timestamp)
        and ah.org_l1_id = #{org_l1_id} and ah.org_id = #{org_id}
      left join hip_ooc_group_v as g on g.ooc_group_id = sc.ooc_group_id
      join dim_comm_tool_v as tool on tool.tool_id = ah.tool_id
      join dim_comm_os_v as os on os.os_id = ah.os_id
    )
    select * from system_status
    order by ooc_group_name, host_name"
  end
  
  # create a count for the deviation and scan dropdown list
  # on the Manage Scans filter page.
  def get_scan_count()
    if @params.nil?
      start_date = ''
      end_date = ''
    else
      start_date = standardize_date(@params[:start_date])
      end_date = standardize_date(@params[:end_date])
    end
    if start_date.empty? && end_date.empty?
      date_limit = "date(s.scan_start_timestamp) between current_date - 31 days and current_date"
    else
      date_limit = "date(s.scan_start_timestamp) between #{SwareBase.quote_value(start_date)} and #{SwareBase.quote_value(end_date)}"
    end
    
    asset_id_list = @params[:assets].map {|a| "(#{a})"}.join(',')
    (org_l1_id, org_id) = @params[:org_id].split(',')
    ooc_scan_type = @params[:ooc_scan_type]
    ooc_group_id = @params[:ooc_group_id]

    gtt_table_name = "hip_gtt_scan"
    prototype = "select s.asset_id, s.scan_id, s.scan_start_timestamp, s.tool_id, t.manager_name, 'y' as used
    from hip_ooc_scan_v as s
    join dim_comm_tool_v as t on t.tool_id = s.tool_id"
    index_on = ['asset_id', 'tool_id', 'scan_start_timestamp']
    
    load_sql = "with asset (asset_id) as (values
    #{asset_id_list}
    ),
    scans as (
      select s.scan_id,
        s.asset_id,
        s.scan_start_timestamp,
        s.tool_id,
        t.manager_name,
        case when ooc_scan.scan_id is not null then 'y' else 'n' end as used
      from asset as a
      join dim_comm_tool_asset_scan_hist_v as s on s.asset_id = a.asset_id
      join dim_comm_tool_v as t on t.tool_id = s.tool_id
      left join hip_scan_v as hc_scan on hc_scan.scan_id = s.scan_id
      left join hip_ooc_scan_v as ooc_scan on ooc_scan.scan_id = s.scan_id
      where s.org_l1_id = #{org_l1_id}
        and hc_scan.scan_id is null
        and ( 
          ( ooc_scan.scan_id is not null
          and ooc_scan.ooc_scan_type = #{SwareBase.quote_value(ooc_scan_type)}
          and ooc_scan.ooc_group_id in (#{@group_id_list_str})
          and ooc_scan.appear_in_dashboard = 'y'
          )
        or #{date_limit}
        )
       and s.scan_service = 'health'
    )
    select count(*) from final table (
      insert into session.hip_gtt_scan (asset_id, scan_id, scan_start_timestamp, tool_id, manager_name, used)
        (select asset_id, scan_id, scan_start_timestamp, tool_id, manager_name, used from scans)
    )"
    
    query = "select s.asset_id, s.scan_id, s.scan_start_timestamp, s.manager_name, s.used, count(f.finding_id) as count
    from session.hip_gtt_scan as s
    left join fact_scan_v as f on f.asset_id = s.asset_id
      and f.org_l1_id = #{org_l1_id}
      and f.scan_tool_id = s.tool_id
      and f.scan_service = 'health'
      and s.scan_start_timestamp between f.row_from_timestamp and coalesce(f.row_to_timestamp, current_timestamp)
      and f.severity_id = 5
    group by s.asset_id, s.scan_id, s.scan_start_timestamp, s.manager_name, s.used
    order by s.scan_start_timestamp desc
    with ur"

    return SwareBase.query_with_temp_table(gtt_table_name, prototype, index_on, load_sql, query)
  end

  # find latest scan for labeling all scans.
  def sql_latest_scan
    "SELECT sh.asset_id, sh.scan_id scan_id, sh.scan_start_timestamp,count(fs.finding_id) AS count
    FROM dim_comm_tool_asset_scan_hist_v as sh
    JOIN hip.dim_comm_tool_asset_hist_v as ah on ah.tool_asset_id = sh.asset_id
      and current_timestamp between ah.row_from_timestamp
      and coalesce(ah.row_to_timestamp, current_timestamp)
    LEFT JOIN hip.fact_scan_v as fs on fs.asset_id = sh.asset_id
      and fs.org_l1_id = #{org_l1_id}
      and fs.org_id = #{org_id}
      and sh.scan_start_timestamp between fs.row_from_timestamp and coalesce(fs.row_to_timestamp, current_timestamp)
      and fs.scan_service = 'health'
      and fs.severity_id=5
      and fs.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})
      and fs.scan_tool_id = sh.tool_id
    left join hip_scan_v as not_scan on not_scan.scan_id = sh.scan_id
    left join hip_ooc_scan_v as has_scan on has_scan.scan_id=sh.scan_id
    WHERE
    sh.scan_start_timestamp between current_timestamp - 31 days and current_timestamp
    and sh.asset_id=#{@params[:asset_id]}
    and sh.scan_service='health'
    and has_scan.scan_id is null
    and not_scan.scan_id is null
    and sh.scan_start_timestamp < current_timestamp
    GROUP BY sh.asset_id,sh.scan_id,sh.scan_start_timestamp
    ORDER BY sh.asset_id,sh.scan_start_timestamp  DESC #{limit_part} "
  end

  def org_conditions
    ["assh.org_l1_id=#{org_l1_id} AND assh.org_id=#{org_id}"]
  end
  def scan_tool_conditions
    "and tool.manager_name = '#{@params[:scan_tool_id]}'" unless @params[:scan_tool_id].blank?
  end
  def scan_type_conditions
    ["and type.ooc_scan_type = '#{@params[:ooc_scan_type]}'",nil] unless @params[:ooc_scan_type].blank?
  end
  def group_type_conditions
    if not @params[:ooc_group_type].blank? 
      ["and group.ooc_group_type = '#{@params[:ooc_group_type]}'",nil]
    end
  end

  def ooc_group_id_conditions
    if ! @params[:ooc_group_id].blank? && @params[:ooc_group_id].downcase!='unassigned' and @params[:ooc_group_id].downcase!='assigned'
      ["grp.ooc_group_id = #{@params[:ooc_group_id]}"]
    elsif @params[:ooc_group_id].downcase=='assigned'
      ["grp.ooc_group_id IS NOT NULL"]
    elsif @params[:ooc_group_id].downcase=='unassigned'
      ["grp.asset_id IS NULL"]
    end
  end

  def system_status_conditions
    ["and asst.system_status = '#{@params[:system_status]}'"] unless @params[:system_status].blank?
  end

  def os_conditions
    ["and asst.os_id=os.os_id AND os.os_product = '#{@params[:os_product]}'"] unless @params[:os_product].blank?
  end

  def host_name_conditions
    ["and lower(asst.host_name) LIKE '%#{@params[:host_name].downcase.strip}%'"] unless @params[:host_name].blank?
  end
  def ip_address_conditions
    ["and asst.ip_string_list LIKE '%#{@params[:ip_address].downcase.strip}%'"] unless @params[:ip_address].blank?
  end

  def hc_sec_class_conditions
    ["and asst.security_policy_name = '#{@params[:hc_sec_class]}'"] unless @params[:hc_sec_class].blank?
  end

  def hc_required_conditions
    unless @params[:hc_required].blank?
      if @params[:hc_required]=='Yes'
        return ["and (asst.hc_auto_flag = 'y' OR asst.hc_manual_flag = 'y')"]
      end
      if @params[:hc_required]=='No'
        return ["and (asst.hc_auto_flag = 'n' AND asst.hc_manual_flag = 'n')"]
      end
    end
  end
  def system_scan_status_condition
    case @params[:system_scan_status]
    when'no_reason'
      "and system_scan_status='Scan Not Available'"
    when 'with_reason'
      "and system_scan_status='Missing, reason provided'"
    when 'available'
      "and system_scan_status='Available, none labeled'"
    when 'released'
      "and system_scan_status='Released'"
    when 'labeled'
      "and system_scan_status='Labeled, none released'"
    when 'missing'
      "and system_scan_status in ('Scan Not Available','Missing, reason provided')"
    when 'incomplete'
      "and system_scan_status in ('Available, none labeled','Labeled, none released','Missing, no reason given' ) "
    when "complete"
      "and system_scan_status in ('Released','Missing, reason provided' )"
    when "no_hc_cycle_scans"
      #this query is used by the dashboard, column b, # systems with no hc cycle scan.
      "and system_scan_status in ('Available, none labeled','Missing, no reason given','Missing, reason provided')"
    end

  end

  def release_date_conditions
    "and publish_ready_timestamp between '#{@params[:release_start_date]}' and '#{@params[:release_end_date]}'" unless (@params[:release_start_date].blank? and @params[:release_end_date].blank?)
  end
  
  def can_be_labeled_conditions
    "and scan_id is null and scan_count > released_scan_count" if @params[:can_be_labeled]
  end

  def standardize_date(date_in)
    return date_in if date_in.empty?
    date = date_in.split('/')
    date_out = "#{date[2]}-#{date[0]}-#{date[1]}"
    return date_out
  end

  def limit_part(n = 1)
    if SwareBase.db2?
      "fetch first #{n} row only"
    else
      "limit #{n}"
    end
  end
end
