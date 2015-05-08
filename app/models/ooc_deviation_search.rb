class OocDeviationSearch
  
  GT_SCAN_TABLE_NAME = "gt_dev_srch_scans"
  GT_FINDING_TABLE_NAME = "gt_dev_srch_finding"
  ROWS_PER_COMMIT = 10000
  CACHE_KEY_SYMBOLS = [
    :clean_scans,
    :deviation_level,
    :host_name,
    :ip_address,
    :org_id,
    :ooc_group_id,
    :ooc_scan_type,
    :os,
    :released,
    :scan_id,
    :severity_id,
    :suppress_id,
    :suppress_status,
    :system_status,
    :val_group,
    :val_status,
    :vuln_text,
    :vuln_title,
  ]
  
  #
  # Disable calls to new from outside the class
  #
  private_class_method :new
  
  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end

#05-16-2013  Added to return groupname for a groupid 

  def self.findgroupname(group_id)
     group_name = ""
     result = SwareBase.set_current_degree(8) do
              SwareBase.find_by_sql(sql(group_id))
     end

     result.each do |row|
          group_name = row.ooc_group_name
     end
   return group_name
  end

  def self.sql(group_id)
     "SELECT ooc_group_name from hip_ooc_group_v WHERE
        ooc_group_id = #{group_id}
        AND ooc_group_status != 'deleted'
        ORDER BY ooc_group_name
   "
  end 
  

  def self.search(params)
    search_params = new(params)
    search_params.search
  end
     

 def search
    #
    # Check to see if the result is already in the cache
    #
    search_param_hash = cache_key
    (l1id, id) = @params[:org_id].split(',')
    cache_set = FindingCacheSet.find_valid_cache_set(@params[:org_id], search_param_hash, :ooc)
    if !cache_set.nil?
      # return the cache result
      result = SwareBase.set_current_degree(8) do
        SwareBase.find_by_sql(deviation_search_sql(cache_set.id, @params[:row_from], @params[:row_to]))
      end
    else
      #
      # No cache set for this search, build one and return the results
      #
      # Make a global temp table containing the scans we are interested in
      SwareBase.query_with_temp_table(GT_SCAN_TABLE_NAME, create_gt_scan_table_sql_template, 
        ["asset_id", "org_l1_id", "org_id", "scan_start_timestamp"], insert_gt_scan_sql, nil)
      # Create a cache set in the building status
      cache_set = FindingCacheSet.create!(
      :cache_set_status => 'building',
      :search_param_hash => search_param_hash,
      :in_cycle => 'n',
      :created_by => SwareBase.user_id,
      :created_at => Time.now.utc,
      :row_count => 0,
      :org_l1_id => l1id,
      :org_id => id )
      # Make a global temp table containing the findings in the result
      SwareBase.query_with_temp_table(GT_FINDING_TABLE_NAME, "select * from hip_finding_cache_element",
        ["cache_set_id", "row_num"], insert_gt_finding_sql(cache_set.id), nil)
      count = SwareBase.find_by_sql("select count(*) as count from session.#{GT_FINDING_TABLE_NAME}")[0][:count]
      # Drop the scans global temp table
      SwareBase.connection.execute("drop table session.#{GT_SCAN_TABLE_NAME}")
      # Move the finding global temp table to the cache set
      from_row = 1
      to_row = ROWS_PER_COMMIT
      while from_row <= count
        SwareBase.find_by_sql(move_temp_table_sql(from_row, to_row))
        from_row += ROWS_PER_COMMIT
        to_row += ROWS_PER_COMMIT
      end
      # Make the cache set as valid
      cache_set.row_count = count
      cache_set.cache_set_status = 'valid'
      cache_set.save!
      # Drop the finding global temp table  
      SwareBase.connection.execute("drop table session.#{GT_FINDING_TABLE_NAME}")
      # Get the results of this search
      result = SwareBase.set_current_degree(8) do
        SwareBase.find_by_sql(deviation_search_sql(cache_set.id, @params[:row_from], @params[:row_to])) 
      end
    end
    return result
  end

  
  def self.find_by_scan(scan, rows)
    search = new({:scan => scan, :limit => rows})
    search.find_by_scan
  end
  
  def find_by_scan
    result = SwareBase.find_by_sql(find_by_scan_sql(@params[:scan], @params[:limit]))
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

RAILS_DEFAULT_LOGGER.debug "OocDevitaionSearch::initialize  group_id_list is #{@group_id_list}"

  end
  
  def org_l1_id
    @params[:org_id].split(',')[0].to_i
  end
  
  def org_id
    @params[:org_id].split(',')[1].to_i
  end

  def order_fragment
    if @params[:order].blank?
      return "order by count asc, row"
    else
      "order by #{@params[:order]}"
    end
  end
  
  def create_gt_scan_table_sql_template
    "select a.org_l1_id,
    	a.org_id,
    	a.tool_asset_id as asset_id,
    	a.tool_asset_vid as asset_vid,
    	a.host_name,
    	a.ip_string_list,
    	a.system_status,
    	s.scan_id,
    	s.scan_start_timestamp,
    	s.publish_ready_timestamp,
    	s.tool_id,
    	g.ooc_group_name as group_name,
        g.ooc_group_id as hc_group_id,
    	t.manager_name,
    	o.os_product
    from dim_comm_tool_asset_hist_v as a
    join hip_ooc_scan_v as s on s.asset_id = a.tool_asset_id
    join hip_ooc_group_v as g on g.ooc_group_id = s.ooc_group_id
    join dim_comm_tool_v as t on t.tool_id = s.tool_id
    join dim_comm_os_v as o on o.os_id = a.os_id"
  end

  def insert_gt_scan_sql
    
# Original and clause  and group.ooc_group_id in (#{group_id_list.join(',')})
#Line 198 seems to be correct
# and group.ooc_group_id in (#{@group_id_list_str})
    "insert into session.#{GT_SCAN_TABLE_NAME}
      with scan as (
        select scan.scan_id,
          scan.scan_start_timestamp,
          scan.tool_name as manager_name,
          scan.publish_ready_timestamp,
          scan.org_l1_id,
          scan.org_id,
          scan.asset_id,
          scan.tool_id,
          group.ooc_group_name as group_name,
          group.ooc_group_id as hc_group_id
        from hip_ooc_scan_v as scan
        join hip_ooc_asset_group_v as ag on ag.asset_id = scan.asset_id
        join hip_ooc_group_v as group on group.ooc_group_id = ag.ooc_group_id
        where scan.org_l1_id = #{org_l1_id}
          and scan.org_id = #{org_id}
          and group.ooc_group_id in (#{@group_id_list_str})
          and scan.ooc_scan_type = #{SwareBase.quote_value(@params[:ooc_scan_type])}
          and scan.ooc_group_id = group.ooc_group_id
          #{released_condition_clause}
        )
        select scan. org_l1_ID,
          scan.org_id,
          a.tool_asset_id,
          a.tool_asset_vid,
          a.host_name,
          a.ip_string_list,
          a.system_status,
          scan.scan_id,
          scan.scan_start_timestamp,
          scan.publish_ready_timestamp,
          scan.tool_id,
          scan.group_name,
          scan.hc_group_id,
          scan.manager_name,
          o.os_product
        from scan
        join hip.dim_comm_tool_asset_hist_v as a on a.org_l1_id = scan.org_l1_id
          and a.org_id = scan.org_id
          and a.tool_asset_id = scan.asset_id
          and current_timestamp between a.row_from_timestamp 
          and coalesce(a.row_to_timestamp, current_timestamp)
        join hip.dim_comm_os_v as o on o.os_id = a.os_id
        where a.system_status <> 'decom'"
  end
  
  def insert_gt_finding_sql(cache_set_id)
    #
    # NOTE!!!!
    #
    # If the folling SQL is changed to use a new column from dim_comm_severity that hold HC severity names
    # (i.e. removing the CASE that provides the deviation_level result column), the function deviation_level_conditions
    # needs to be updated as well.
    #
    "with deviation as (
     select 
     assets.org_l1_id,
     assets.org_id,
     assets.scan_id,
     assets.asset_id,
     assets.asset_vid,
     fact.finding_vid,
     fact.finding_hash,
     fact.finding_id,
     fact.finding_text,
     fact.cat_name,
     assets.host_name,
     assets.ip_string_list,
     assets.system_status,
     fact.vuln_id,
     fact.severity_id,
     assets.os_product,
     assets.scan_start_timestamp,
     assets.manager_name,
     assets.publish_ready_timestamp,
     assets.group_name,
     assets.hc_group_id
     from session.#{GT_SCAN_TABLE_NAME} assets
     join hip.fact_scan_v as fact on fact.asset_id = assets.asset_id
     and fact.org_l1_id = assets.org_l1_id
     and fact.org_id = assets.org_id
     and fact.scan_service = 'health'
    #{clean_scan_condition_clause}
     and assets.scan_start_timestamp between fact.row_from_timestamp 
     and coalesce(fact.row_to_timestamp, current_timestamp)
     and #{severity_id_condition_clause}
     and fact.scan_tool_id = assets.tool_id
    ), 
    suppression as (
     select suppf.finding_id,
     supp.org_l1_id ,
     supp.org_id ,
     suppf.lu_timestamp as suppress_timestamp,
     supp.suppress_name,
     supp.suppress_class,
     suppf.suppress_id,
     supp.start_timestamp,
     supp.end_timestamp
     from hip.hip_suppress_v as supp
     join hip.hip_suppress_finding_v as suppf on suppf.suppress_id = supp.suppress_id
     where supp.org_l1_id = #{org_l1_id}
     and supp.org_id = #{org_id}
     and current_timestamp between supp.start_timestamp and supp.end_timestamp
    ), 
    #{suppress_status_with}
    deviation_select as (
      select
        d.scan_id,
        d.finding_id,
        d.finding_vid,
        d.asset_vid,
        d.host_name,
        d.publish_ready_timestamp,
        d.group_name,
        d.hc_group_id,
        supp.suppress_timestamp,
        supp.suppress_id
    from deviation d
    join hip.dim_comm_vuln_v as vuln on vuln.vuln_id = d.vuln_id
    join hip.dim_comm_severity_v as sev on sev.severity_id = d.severity_id
    left join suppression as supp on supp.finding_id = d.finding_id
      and supp.org_l1_id = d.org_l1_id
      and supp.org_id = d.org_id
    #{suppress_status_join}
    #{!conditions.blank? ? "where #{conditions}" : ""}  
    )
    select count(*) as count
      from final table(
      insert into session.#{GT_FINDING_TABLE_NAME} (
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
        select #{cache_set_id},
        row_number() over(ORDER BY host_name, finding_vid) as row_num,
        SCAN_ID,
        FINDING_VID,
        ASSET_VID,
        PUBLISH_READY_TIMESTAMP,
        GROUP_NAME,
        hc_group_id,
        SUPPRESS_TIMESTAMP,
        SUPPRESS_ID,
        'y',
        #{Time.now.utc.wday+1}
        from deviation_select
      )
    )"
  end
  
  def move_temp_table_sql(start_row, end_row)
    "-- Start Move Temp Table
    select count(*) from final table (
    insert into hip_finding_cache_element_v (
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
    from session.#{GT_FINDING_TABLE_NAME}
    where row_num between #{start_row} and #{end_row}
    ))
    -- End Move Temp Table"
  end

  def deviation_search_sql(cache_set_id, start_row, end_row)

#  Old as clause on line 393 was ** ce.hc_group_id as ooc_group_id,
#  New line 393 ** ce.hc_group_id,
 # New - Line 430  where ce.cache_set_id = #{cache_set_id} and ce.hc_group_id in (#{@group_id_list_str}) and row_num between #{start_row} and #{end_row}
 # where ce.cache_set_id = #{cache_set_id} and row_num between #{start_row} and #{end_row}

    sql = "select cs.row_count as count,
    ce.scan_id,
    fact.finding_id,
    ce.finding_vid,
    fact.cat_name,
    fact.finding_text,
    fact.finding_hash,
    asst.host_name,
    asst.ip_string_list,
    asst.tool_asset_id as asset_id,
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
      when ce.valid_finding_flag = 'y' then 'Valid'
      else 'Not Validated' end as validation_status,
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
    where ce.cache_set_id = #{cache_set_id} and ce.hc_group_id in (#{@group_id_list_str}) 
   order by row_num" 
  end
   
  def find_by_scan_sql(scan, limit)
    sql = "
    with suppressions as (
      select s.suppress_class, s.suppress_name, sf.finding_id
      from hip_suppress_v as s
      join hip_suppress_finding_v as sf on sf.suppress_id = s.suppress_id
      where (s.org_l1_id, s.org_id) = (#{scan.org_l1_id}, #{scan.org_id})
      and #{SwareBase.quote_value(scan.publish_ready_timestamp)} between s.start_timestamp and s.end_timestamp
    )
    select tool.manager_name,
    vuln.title,
    fact.finding_text,
    fact.cat_name,
    vuln.sarm_cat_name,
    supp.suppress_class,
    supp.suppress_name,
    case 
      when supp.finding_id is not null then 'Suppressed' 
      else 'Valid' end as validation_status
    from fact_scan_v as fact
    join dim_comm_tool_v as tool on tool.tool_id = fact.scan_tool_id
    join dim_comm_vuln_v as vuln on vuln.vuln_id = fact.vuln_id
    left join suppressions as supp on supp.finding_id = fact.finding_id
    where asset_id = #{scan.asset_id}
      and fact.severity_id = 5
      and fact.scan_service = 'health'
      and (fact.org_l1_id, fact.org_id) =  (#{scan.org_l1_id}, #{scan.org_id})
      and fact.scan_tool_id = #{scan.tool_id}
      and #{SwareBase.quote_value(scan.scan_start_timestamp)} between fact.row_from_timestamp and coalesce(fact.row_to_timestamp, current_timestamp)
    order by validation_status asc, suppress_class asc, suppress_name asc, title asc, finding_text asc
    fetch first #{limit} rows only
    "
  end

  def system_status_conditions
    if ! @params[:system_status].blank?
      ["d.system_status = #{SwareBase.quote_value(@params[:system_status])}",nil]
    end
  end

  # include or exclude clean scans in the result
  # default from filter page is to exclude clean scans
  def clean_scan_condition_clause
    if @params[:clean_sans].blank? or @params[:clean_scans]=='no'
      "and fact.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})"
    elsif @params[:clean_scans]=='yes'
      return # no extra conditions to produce
    end
  end
 
  def released_condition_clause
    if @params[:released].blank?
      # this is the default
      return "and scan.publish_ready_timestamp is null"
    elsif @params[:released]=="yes"
      # show released deviations/findings
      return "and scan.publish_ready_timestamp is not null"
    elsif @params[:released]=="no"
      # show not released devaitions/findings
      return  "and scan.publish_ready_timestamp is null"
    else @params[:released]=="all"
      return ""
    end
  end

  def scan_id_conditions
    ["d.scan_id=#{@params[:scan_id].to_i}",nil] unless @params[:scan_id].blank?
  end


  def deviation_level_conditions
    severity_cd = {
      "All" => "All",
      "Compliant" => "allowed",
      "Info" => "info",
      "Violation" => "high",
      "Warning" => "low"
    }[@params[:deviation_level] ||= "All"]
    ["sev.severity_cd = #{SwareBase.quote_value(severity_cd)}",nil] unless severity_cd == 'All'
  end

  def severity_id_condition_clause
    if @params[:severity_id].blank?
      return "fact.severity_id = 5"
    else
      return "fact.severity_id in (#{@params[:severity_id]})"
    end
  end
  
  def val_group_conditions
    if @params[:val_group].downcase!="all" and @params[:val_group].downcase!='unk'
      return ["coalesce(d.cat_name, vuln.sarm_cat_name)=#{SwareBase.quote_value(@params[:val_group])}",nil]
    end

    if @params[:val_group].downcase=='unk'
      return ["coalesce(d.cat_name, vuln.sarm_cat_name) is null",nil]
    end
  end

  def vuln_title_conditions
    ["d.vuln_id in (select vuln_id from dim_comm_vuln_v where title =#{SwareBase.quote_value(@params[:vuln_title].strip)})",nil] unless @params[:vuln_title].blank?
  end

  def vuln_text_conditions
    ["LOWER(d.finding_text) like #{SwareBase.quote_value('%' + @params[:vuln_text].downcase.strip + '%')}",nil]unless @params[:vuln_text].blank?
  end

  def suppress_id_conditions
    ["supp.suppress_id=#{@params[:suppress_id].to_i}",nil] unless @params[:suppress_id].blank?
  end

  def suppress_status_with
    if ['none', 'expired'].include? @params[:suppress_status]
      "suppression_expired as (
       select suppf.finding_id,
       supp.org_l1_id ,
       supp.org_id ,
       suppf.lu_timestamp as suppress_timestamp,
       supp.suppress_name,
       supp.suppress_class,
       suppf.suppress_id,
       supp.start_timestamp,
       supp.end_timestamp
       from hip.hip_suppress_v as supp
       join hip.hip_suppress_finding_v as suppf on suppf.suppress_id = supp.suppress_id
       where supp.org_l1_id = #{org_l1_id}
       and supp.org_id = #{org_id}
       and supp.end_timestamp < current_timestamp
      ),"
    else
      ''
    end
  end

  def suppress_status_join
    if ['none', 'expired'].include? @params[:suppress_status]
      "left join suppression_expired as supp_expired on supp_expired.finding_id = d.finding_id
        and supp_expired.org_l1_id = d.org_l1_id
        and supp_expired.org_id = d.org_id"
    else
      ''
    end
  end

  def suppress_status_conditions
    sql = case @params[:suppress_status]
    when 'none'
      'supp.suppress_id is null and supp_expired.suppress_id is null'
    when 'expired'
      'supp.suppress_id is null and supp_expired.suppress_id is not null'
    when 'current'
      'supp.suppress_id is not null'
    when 'current_expiring'
      "supp.suppress_id is not null
       and (current_timestamp + 3 months) not between supp.start_timestamp and supp.end_timestamp"
    when 'current_not_expiring'
      "supp.suppress_id is not null
       and (current_timestamp + 3 months) between supp.start_timestamp and supp.end_timestamp"
    end
    [sql, nil] unless sql.blank?
  end

  def val_status_conditions
    unless @params[:val_status].blank?
      if @params[:val_status]=="suppressed"
        return ["supp.finding_id is not null",nil]
      elsif @params[:val_status]=='valid_suppressed'
        return ["(supp.finding_id is not null)",nil]
      elsif @params[:val_status]=='valid'
        return ["(supp.finding_id is null)", nil] 
      end
    end
  end

  def ip_address_conditions
    ["d.ip_string_list like #{SwareBase.quote_value('%' + @params[:ip_address].strip + '%')}",nil] unless @params[:ip_address].blank?
  end

  def host_name_conditions
    ["LOWER(d.host_name) like #{SwareBase.quote_value('%' + @params[:host_name].downcase.strip + '%')}",nil] unless @params[:host_name].blank?
  end

  def os_conditions
    ["d.os_product = #{SwareBase.quote_value(@params[:os])}",nil] unless @params[:os].blank?
  end

  # TODO:  Remove this commented out function -- scan type is required
  #def scan_type_conditions
  #  ["scan.ooc_scan_type='#{@params[:ooc_scan_type]}'"] unless @params[:ooc_scan_type].blank?
  #end

  def conditions
    [conditions_clauses.join(' AND '), *conditions_options].join('') unless conditions_options.blank?
  end

  def conditions_clauses
    conditions_parts.map { |condition| condition.first }
  end

  def conditions_options
    conditions_parts.map { |condition| condition[1..-1] }.flatten
  end

  def conditions_parts
    self.private_methods.grep(/_conditions$/).map { |m| send(m) }.compact
  end
  
  def cache_key
    key = returning("OOCYCLE") do |string|
      CACHE_KEY_SYMBOLS.each do |params_symbol|
        value = @params[params_symbol]
        RAILS_DEFAULT_LOGGER.debug "#{params_symbol} #{value}"
        string << (value.blank? ? '' : value.to_s)
      end
    end.hash
  end

  

  
end
