class DeviationSearch

  #used for search page only
  attr_accessor :hc_group_id, :val_group,:val_status,:ip_address,
  :per_page,:sort,:vuln_title,:host_name, :os, :org_id,:vuln_text, :suppress_status, :suppress_id, :deviation_level,
  :scan_type

  TEMP_TABLE_NAME = "session.finding_temp"
  ROWS_PER_COMMIT = 10000

  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end


  # query for a list of assets
  def self.search(params,rows_from,rows_to)
    @hc_group_id=params['hc_group_id']
    @val_group=params['val_group']
    @val_status=params['val_status']
    @ip_address = params['ip_address']
    @vuln_title = params['vuln_title']
    @vuln_text = params['vuln_text']
    @suppress_id = params['suppress_id']
    @suppress_status = params['suppress_status']
    @org_id=params['org_id']
    @sort=params['sort']
    @host_name=params['host_name']
    @os=params['os']
    @scan_id=params['scan_id']
    @not_released=params['not_released']
    @order=params['order']
    @latest_released=params['latest_released']
    @sys_status = nil
    @clean_scans=params['clean_scans']
    @deviation_level=params['deviation_level']
    @rows_to= rows_to
    @rows_from = rows_from
    find_sql
  end

  def self.get_latest_released_clean_scans(org_id, hc_group_id)
    # Note:  This query only uses the summary tables
    (o1id, oid) = org_id.split(',')
    query = "-- get_latest_released_clean_scans
with all_scans as (
  select dsap.hc_group_name, dsap.host_name, dssp.*
  from hip.dim_scan_asset_period_v as dsap
  JOIN hip.dim_scan_scan_period_v AS dssp ON dsap.asset_vid = dssp.asset_vid
    AND dsap.org_l1_id = dssp.org_l1_id
    AND dsap.org_id = dssp.org_id
    AND dsap.period_month_id = dssp.period_month_id
    and dssp.publish_ready_timestamp is not null
  where dsap.period_month_id = #{SwareBase.current_month_period_id}
    and dsap.org_l1_id = #{o1id}
    and dsap.org_id = #{oid}
    and dsap.hc_group_id = #{hc_group_id}
),
clean_scans as (
  select alls.hc_group_name, alls.host_name, alls.asset_vid, alls.scan_id, alls.publish_ready_timestamp,
    alls.scan_start_timestamp
  from all_scans as alls
  left join hip.facts_scan_period_v as fp on alls.org_l1_id = fp.org_l1_id
    and alls.org_id = fp.org_id
    and alls.period_month_id = fp.period_month_id
    and alls.asset_vid = fp.asset_vid
    and fp.severity_id = 5
    and fp.tool_id = alls.tool_id
  group by alls.hc_group_name, alls.host_name, alls.asset_vid, alls.scan_id, alls.publish_ready_timestamp, alls.scan_start_timestamp
  having count(fp.finding_id) = 0
)
select *
from clean_scans as cs
where cs.publish_ready_timestamp = (select max(al1.publish_ready_timestamp) from all_scans as al1 where al1.asset_vid = cs.asset_vid)      "
    return SwareBase.find_by_sql(query)
  end

  private

  def self.find_sql
    search_param_hash = cache_key
    (l1id, id) = @org_id.split(',')
    cache_set = FindingCacheSet.find_valid_cache_set(@org_id, search_param_hash, :incycle)
    if !cache_set.nil?
      # return the cache result
      result = SwareBase.set_current_degree(8) do
        SwareBase.find_by_sql(deviation_search_sql(cache_set.id, @rows_from, @rows_to))
RAILS_DEFAULT_LOGGER.debug "DevitaionSearch::search - line 88 - find_by_sql deviation_search_sql result is #{result}"
      end
    else
      # Create / populate cache / return rows
      cache_set = FindingCacheSet.create!(
        :cache_set_status => 'building',
        :search_param_hash => search_param_hash,
        :in_cycle => 'y',
        :created_by => SwareBase.user_id,
        :created_at => Time.now.utc,
        :row_count => 0,
        :org_l1_id => l1id,
        :org_id => id )
      # Create temp table
      create_temp_table
      # Populates the temp table
      count = SwareBase.find_by_sql(load_temp_table_sql(cache_set.id) )[0][:count]
      # Move data from temp table to cache entries table, a certain number of rows at a time,
      # commiting after each block
      from_row = 1
      to_row = ROWS_PER_COMMIT
      while from_row <= count
        SwareBase.find_by_sql(move_temp_table_sql(from_row, to_row))
        from_row += ROWS_PER_COMMIT
        to_row += ROWS_PER_COMMIT
      end
      # Update cache set
      cache_set.row_count = count
      cache_set.cache_set_status = 'valid'
      cache_set.save!
      # Delete temp table
      drop_temp_table
      # Finally, return rows from the cache
      result = SwareBase.set_current_degree(8) do
        SwareBase.find_by_sql(deviation_search_sql(cache_set.id, @rows_from, @rows_to))
      end
    end
    return result
  end
  
  def self.load_temp_table_sql(cache_set_id)
    #
    # NOTE!!!!
    #
    # If the following SQL is changed to use a new column from dim_comm_severity that hold HC severity names
    # (i.e. removing the CASE that provides the deviation_level result column), the function deviation_level_conditions
    # needs to be updated as well.
    #
    # NOTE!!!!
    #
    # If the tables used by this query change, any new tables need to have a before_save and before_destory callback
    # call SwareBase.clear_deviation_cache_info, and also any methods that use execute will need to call it directly.
    # Any tables removed should have thier equivalent callbacks removed.
    #
    #period = SwareBase.current_period
    (l1id, id) = @org_id.split(',')
    # Determin sort order.  It will be used in two places:  1) the row_number function and 2) the order by clause
    if @order.blank?
      order_fragment = "host_name #{@sort}, finding_id"
    else
      order_fragment = "#{@order}, finding_id"
    end
    sql="-- START OF QUERY
    with suppress as (
      select
      sf.suppress_id,
      sf.finding_id,
      sf.lu_timestamp,
      s.start_timestamp,
      s.end_timestamp
      from hip_suppress_v as s
      join hip_suppress_finding_v as sf on sf.suppress_id = s.suppress_id
      where s.org_l1_id = #{l1id} and s.org_id = #{id}
        and #{SwareBase.connection.quote(SwareBase.HcCycleAssetFreezeTimestamp)} between s.start_timestamp and s.end_timestamp
    ),
    #{suppress_status_with}
    deviation as (
      select
        fp.scan_id, 
        fp.finding_id,
        fp.finding_vid, 
        dsap.asset_vid,
        dssp.publish_ready_timestamp,
        dsap.hc_group_name as group_name, 
        dsap.hc_group_id, 
        sfs1.lu_timestamp as suppress_timestamp,
        sfs1.suppress_id,
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
      left join suppress as sfs1 on sfs1.finding_id = fp.finding_id
      #{suppress_status_join}
      where dsap.period_month_id = #{SwareBase.current_month_period_id}
        and dsap.org_l1_id = #{l1id}
        and dsap.org_id = #{id} #{" AND " unless conditions.blank?} #{conditions.join('')}
    ),
    deviation_with_row_num as (
      SELECT
        scan_id, 
        finding_id,
        finding_vid, 
        asset_vid,
        publish_ready_timestamp,
        group_name, 
        hc_group_id, 
        suppress_timestamp,
        suppress_id,
        valid_finding_flag,
        row_number() over(ORDER BY host_name asc, finding_id) as row_num
      FROM deviation
    )
    select count(*) as count
    from final table (
      insert into #{TEMP_TABLE_NAME} (CACHE_SET_ID,
        ROW_NUM,
        SCAN_ID,
        FINDING_VID,
        ASSET_VID,
        PUBLISH_READY_TIMESTAMP,
        GROUP_NAME,
        HC_GROUP_ID,
        SUPPRESS_TIMESTAMP,
        SUPPRESS_ID,
        VALID_FINDING_FLAG,
        DAY_OF_WEEK
        ) (
        select #{cache_set_id},
        ROW_NUM,
        SCAN_ID,
        FINDING_VID,
        ASSET_VID,
        PUBLISH_READY_TIMESTAMP,
        GROUP_NAME,
        HC_GROUP_ID,
        SUPPRESS_TIMESTAMP,
        SUPPRESS_ID,
        VALID_FINDING_FLAG,
        #{Time.now.utc.wday+1}
        from deviation_with_row_num)
      )
    -- End of Query"
    RAILS_DEFAULT_LOGGER.debug "cache_key:  #{cache_key}"
    sql
  end
   
  def self.joins
    joins = []
    return joins
  end

  def self.not_released_conditions
    if @not_released.blank?
      # from orginal query, to only show not released
      # this is the default, used from filter page
      return ["dssp.publish_ready_timestamp is null",nil]
    elsif @not_released=="no"
      # show released deviations/findings
      return ["dssp.publish_ready_timestamp is not null",nil]
    elsif @not_released=="yes"
      # show not released devaitions/findings
      return  ["dssp.publish_ready_timestamp is null",nil]
    else @not_released=="all"
      return
    end
  end

  # include or exclude clean scans in the result
  # default from filter page is to exclude clean scans
  def self.clean_scan_conditions
    if @clean_scans.blank?
      ["fp.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})"]
    elsif @clean_scans=='yes'
      return # no extra conditions to produce
    elsif @clean_scans=='no'
      ["fp.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})"]
    end
  end
  
  def self.scan_id_conditions
    ["fp.scan_id=#{@scan_id}",nil] unless @scan_id.blank?
  end
  
  def self.system_status_conditions
    ["dsap.system_status='prod'",nil]
  end
  
  def self.deviation_level_conditions
    severity_cd = {
      "All" => "All",
      "Compliant" => "allowed",
      "Info" => "info",
      "Violation" => "high",
      "Warning" => "low"
      }[@deviation_level ||= "All"]
    ["sev.severity_cd = #{SwareBase.quote_value(severity_cd)}",nil] unless severity_cd == 'All'
  end
  
  
  def self.hc_group_id_conditions
    if @hc_group_id.blank?
      return nil
    elsif @hc_group_id.kind_of?(Array)
      hc_group_id_list = @hc_group_id.map {|group_id| group_id.to_i}
    else
      hc_group_id_list = [@hc_group_id.to_i]
    end
    return ["dsap.hc_group_id in (#{hc_group_id_list.join(',')})",nil]
  end
  
  def self.val_group_conditions
    if @val_group.downcase!="all" and @val_group.downcase!='unk'
      return ["coalesce(fact.cat_name, vuln.sarm_cat_name)='#{@val_group}'",nil]
    end
  
    if @val_group.downcase=='unk'
      return ["coalesce(vuln.sarm_cat_name,fact.cat_name) is null",nil]
    end
  end

  def self.vuln_title_conditions
    ["fp.vuln_id in (select vuln_id from dim_comm_vuln_v where title ='#{@vuln_title.strip}')"]unless @vuln_title.blank?
  end
  
  def self.vuln_text_conditions
    ["LOWER(fp.finding_text) like '%#{@vuln_text.downcase.strip}%'",nil]unless @vuln_text.blank?
  end
  
  def self.suppress_id_conditions
    unless @suppress_id.blank?
      ["sfs1.suppress_id=#{@suppress_id}",nil] unless @suppress_id=='all'
    end
  end

  def self.suppress_status_with
    if ['none', 'expired'].include? @suppress_status
      (l1id, id) = @org_id.split(',')
      "suppress_expired as (
        select sf.suppress_id, sf.finding_id, sf.lu_timestamp
        from hip_suppress_v as s
        join hip_suppress_finding_v as sf on sf.suppress_id = s.suppress_id
        where s.org_l1_id = #{l1id} and s.org_id = #{id}
          and s.end_timestamp < #{SwareBase.connection.quote(SwareBase.HcCycleAssetFreezeTimestamp)}
      ),"
    else
      ''
    end
  end

  def self.suppress_status_join
    if ['none', 'expired'].include? @suppress_status
      "left join suppress_expired as supp_expired on supp_expired.finding_id = fp.finding_id"
    else
      ''
    end
  end

  def self.suppress_status_conditions
    sql = case @suppress_status
    when 'none'
      'sfs1.suppress_id is null and supp_expired.suppress_id is null'
    when 'expired'
      'sfs1.suppress_id is null and supp_expired.suppress_id is not null'
    when 'current'
      'sfs1.suppress_id is not null'
    when 'current_expiring'
      # TODO: use #{SwareBase.connection.quote(SwareBase.HcCycleAssetFreezeTimestamp)}
      "sfs1.suppress_id is not null
       and (current_timestamp + 3 months) not between sfs1.start_timestamp and sfs1.end_timestamp"
    when 'current_not_expiring'
      "sfs1.suppress_id is not null
       and (current_timestamp + 3 months) between sfs1.start_timestamp and sfs1.end_timestamp"
    end
    [sql, nil] unless sql.blank?
  end

  def self.val_status_conditions
    case_element = "CASE WHEN sfs1.finding_id is NOT NULL THEN 'Suppressed' ELSE 'Valid' END"
    unless @val_status.blank?
      if @val_status=="suppressed"
        return ["#{case_element} = 'Suppressed'",nil]
      elsif @val_status == 'valid'
        return ["#{case_element} = 'Valid'",nil] 
      end
    end
  end
  
  def self.ip_address_conditions
    ["dsap.ip_string_list like '%#{@ip_address.strip}%'",nil] unless @ip_address.blank?
  end
  
  def self.host_name_conditions
    ["LOWER(dsap.host_name) like '%#{@host_name.downcase.strip}%'",nil] unless @host_name.blank?
  end
  
  def self.os_conditions
    ["os.os_product = '#{@os}'",nil] unless @os.blank?
  end

  def self.latest_released_conditions
    ["dssp.publish_ready_timestamp =
      (select max(s1.publish_ready_timestamp) from dim_scan_scan_period_v as s1
      join dim_scan_scan_period_v as h1 on h1.scan_id = s1.scan_id
      where h1.asset_vid = dsap.asset_vid and s1.period_month_id = dssp.period_month_id
      )",nil] unless @latest_released.blank?
  end
  
  def self.conditions
    unless conditions_options.blank?
      [conditions_clauses.join(' AND '), *conditions_options]
    else
      []
    end
  end
  
  def self.conditions_clauses
    conditions_parts.map { |condition|  condition.first }
  end
  
  def self.conditions_options
    conditions_parts.map { |condition| condition[1..-1] }.flatten
  end
  
  def self.conditions_parts
    self.methods.grep(/_conditions$/).map { |m| send(m) }.compact
  end

  CACHE_KEY_VARIABLES = [
    "@hc_group_id",
    "@val_group",
    "@val_status",
    "@ip_address",
    "@vuln_title",
    "@vuln_text",
    "@suppress_id",
    "@suppress_status",
    "@org_id",
    "@sort",
    "@host_name",
    "@os",
    "@scan_id",
    "@not_released",
    "@order",
    "@latest_released",
    "@sys_status",
    "@clean_scans",
    "@deviation_level",
    ].sort

  def self.cache_key
    key = "HCCYCLE".tap do |string|
      CACHE_KEY_VARIABLES.each do |variable_name|
        value = eval(variable_name)
        RAILS_DEFAULT_LOGGER.debug "#{variable_name} #{value}"
        string << (value.blank? ? '' : value.to_s)
      end
    end.hash
  end

  def self.move_temp_table_sql(start_row, end_row)
    "-- Start Move Temp Table
    select count(*) from final table (
    insert into #{FindingCacheElement.table_name} (
    CACHE_SET_ID,
    ROW_NUM,
    SCAN_ID,
    FINDING_VID,
    ASSET_VID,
    PUBLISH_READY_TIMESTAMP,
    GROUP_NAME,
    HC_GROUP_ID,
    SUPPRESS_TIMESTAMP,
    SUPPRESS_ID,
    VALID_FINDING_FLAG,
    DAY_OF_WEEK
    ) (
    select 
    CACHE_SET_ID,
    ROW_NUM,
    SCAN_ID,
    FINDING_VID,
    ASSET_VID,
    PUBLISH_READY_TIMESTAMP,
    GROUP_NAME,
    HC_GROUP_ID,
    SUPPRESS_TIMESTAMP,
    SUPPRESS_ID,
    VALID_FINDING_FLAG,
    DAY_OF_WEEK
    from #{TEMP_TABLE_NAME}
    where row_num between #{start_row} and #{end_row}
    ))
    -- End Move Temp Table"
  end

  def self.deviation_search_sql(cache_set_id, start_row, end_row)
    sql = "select
      cs.row_count as count,
      ce.scan_id,
      ce.finding_vid,
      fact.finding_id,
      fact.cat_name,
      fact.finding_text,
      fact.finding_hash,
      asst.host_name,
      asst.ip_string_list,
      ce.group_name,
      ce.hc_group_id,
      cs.org_l1_id,
      cs.org_id,
      fact.asset_id,
      vuln.title,
      vuln.sarm_cat_name,
      os.os_product,
      scan.scan_start_timestamp,
      ce.publish_ready_timestamp,
      tool.manager_name,
      ce.suppress_id,
      ce.suppress_timestamp as suppress_date,
      supp.suppress_name,
      supp.suppress_class,
      supp.end_timestamp as suppress_end_timestamp,
      case when ce.suppress_id is not null then 'Suppressed'
        else 'Valid' end as validation_status,
      case when sev.severity_cd = 'allowed' then 'compliant'
        when sev.severity_cd = 'low' then 'warning'
        when sev.severity_cd = 'high' then 'violation'
        else sev.severity_cd end as deviation_level,
      case when supp2.suppress_id = ce.suppress_id then null else supp2.suppress_id end as non_current_suppress_id,
      case when supp2.suppress_id = ce.suppress_id then null else supp2.suppress_name end as non_current_suppress_name,  
      row_num as row
      from hip_finding_cache_element_v as ce
      join hip_finding_cache_set_v as cs on cs.cache_set_id = ce.cache_set_id
      join fact_scan_v as fact on fact.finding_vid = ce.finding_vid
      join dim_comm_vuln_v as vuln on vuln.vuln_id = fact.vuln_id
      join dim_comm_tool_asset_hist_v as asst on asst.tool_asset_vid = ce.asset_vid and asst.org_l1_id = cs.org_l1_id
      join dim_comm_os_v as os on os.os_id = asst.os_id
      join dim_comm_tool_asset_scan_hist_v as scan on scan.scan_id = ce.scan_id and scan.org_l1_id = cs.org_l1_id and scan.org_id = cs.org_id
      join dim_comm_tool_v as tool on tool.tool_id = scan.tool_id
      join dim_comm_severity_v as sev on sev.severity_id = fact.severity_id
      left join hip_suppress_v as supp on supp.suppress_id = ce.suppress_id
      left join hip_suppress_finding_v as hsf on hsf.finding_id = fact.finding_id
      left join hip_suppress_v as supp2 on supp2.suppress_id = hsf.suppress_id
      where ce.cache_set_id = #{cache_set_id} and row_num between #{start_row} and #{end_row}
      order by row_num"
  end

  def self.create_temp_table
    sql = "declare global temporary table #{TEMP_TABLE_NAME} like hip.hip_finding_cache_element with replace
    on commit preserve rows not logged"
    SwareBase.connection.execute(sql)
    sql = "create index #{TEMP_TABLE_NAME}_key on #{TEMP_TABLE_NAME} (row_num)"
    SwareBase.connection.execute(sql)
  end
  
  def self.drop_temp_table
    sql = "drop table #{TEMP_TABLE_NAME}"
  end

end
