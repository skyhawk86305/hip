class ScanSearch

  attr_accessor :hc_group_id, :scan_tool_id,:scan_type,:start_date,:end_date,
    :page,:per_page,:sort,:host_name, :org_id,:ip_address,:system_scan_status,
    :system_status,:os_product,:hc_required,:hc_interval,:hc_sec_class

  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end

  # query for a list of assets
  def self.search(params)
    @hc_group_id=params['hc_group_id']
    @scan_tool_id=params['scan_tool_id']
    @scan_type=params['scan_type']
    @start_date=standardize_date(params['start_date'])
    @end_date = standardize_date(params['end_date'])
    @ip_address = params['ip_address']
    @org_id=params['org_id']
    @sort=params['sort']
    @host_name=params['host_name']
    @system_scan_status=params['system_scan_status']
    find_scans
  end

  # get a list of hc_cycle_scans for dashboard
  def self.hc_cycle_scans(org)
    @scan_type='HC Cycle'
    @hc_group_id='all'
    @scan_tool_id='all'
    @start_date = nil
    @end_date = nil
    @ip_address = nil
    @sort=nil
    @host_name=nil
    @org_id=org.id.join(',')
    AssetScan.find_by_sql sql()
  end
  # creat a count for the deviation and scan dropdown list
  # on the Manage Scans filter page.

  def self.scan_count(asset_scans, params, current_period_limit = false)
    assets=[]
    asset_scans.each do |as|
      assets.push(as.asset_id)
    end
    (org_l1_id,org_id)=params['org_id'].split(",")
    
    if params.nil?
      start_date = ''
      end_date = ''
    else
      start_date = standardize_date(params['start_date'])
      end_date = standardize_date(params['end_date'])
    end
    if start_date.empty? && end_date.empty?
      date_limit = ''
    else
      date_limit = "and cast(sh.scan_start_timestamp as date) between '#{start_date}' and '#{end_date}'" 
    end
    
    if current_period_limit
      current_period_where_clause = "and year(sh.scan_start_timestamp) = #{SwareBase.HcCycleAssetFreezeTimestamp.year} and month(sh.scan_start_timestamp) = #{SwareBase.HcCycleAssetFreezeTimestamp.month}"
    else
      current_period_where_clause = ''
    end

    sql="with asset_ids (asset_id) as (values #{assets.join(",")})
    SELECT sh.asset_id,tool.manager_name, sh.scan_id, sh.scan_start_timestamp ,count(fs.finding_id) AS count
    FROM asset_ids as a
    JOIN dim_comm_tool_asset_scan_hist_v as sh on sh.asset_id = a.asset_id
      and sh.org_id = #{org_id}
      and sh.scan_service = 'health'
      #{current_period_where_clause}
      #{date_limit}
      and sh.scan_start_timestamp < current_timestamp
    LEFT JOIN hip_ooc_scan_v as oscan on oscan.scan_id = sh.scan_id
    JOIN dim_comm_tool_asset_hist_v as ah on ah.tool_asset_id = sh.asset_id
      and ah.org_id = #{org_id}
      and #{AssetScan.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between ah.row_from_timestamp and coalesce(ah.row_to_timestamp, current_timestamp)
      and oscan.scan_id is null
    JOIN dim_comm_tool_v as tool on tool.tool_id=sh.tool_id
    LEFT JOIN fact_scan_v as fs on fs.asset_id = sh.asset_id
      and fs.org_l1_id = #{org_l1_id}
      and fs.org_id = #{org_id}
      and fs.scan_service = 'health'
      and sh.scan_start_timestamp between fs.row_from_timestamp and coalesce(fs.row_to_timestamp, current_timestamp)
      and fs.severity_id=5
      and fs.scan_tool_id = sh.tool_id
    GROUP BY sh.asset_id,tool.manager_name,sh.scan_id,sh.scan_start_timestamp
    ORDER BY sh.asset_id,sh.scan_start_timestamp  DESC"
    AssetScan.find_by_sql sql
  end
  
  def self.latest_scan(asset_id,current_org_id)
    (org_l1_id,org_id)=current_org_id.split(",")
    # Get latest available scan in the current period
    sql = "SELECT sh.asset_id, sh.scan_id scan_id, sh.scan_start_timestamp
    FROM dim_comm_tool_asset_scan_hist_v as sh
    JOIN dim_comm_tool_asset_hist_v as ah on ah.tool_asset_id = sh.asset_id
      and #{AssetScan.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between ah.row_from_timestamp and coalesce(ah.row_to_timestamp, current_timestamp)
    left join hip_scan_v as hscan on hscan.scan_id = sh.scan_id
    left join hip_ooc_scan_v as ooc on ooc.scan_id = sh.scan_id
    WHERE
    year(sh.scan_start_timestamp) = year(current_date) and month(sh.scan_start_timestamp) = month(current_date)
    and sh.asset_id = #{asset_id}
    and sh.scan_service = 'health'
    and hscan.scan_id is null
    and ooc.scan_id is null 
    and sh.scan_start_timestamp < current_timestamp
    ORDER BY sh.asset_id,sh.scan_start_timestamp  DESC #{limit_part}"
    AssetScan.find_by_sql sql
  end

  private

  # query for paination for review
  def self.find_scans
    AssetScan.find_by_sql sql() #, :page => @page, :per_page=>@per_page
  end

  def self.sql
    #This query should return what you need.
    #The count columns are provided so that you can do where clauses based on them if needed (like to determine if
    #there are unlabeled scans available, you see if scan_count > hc_cycle_count)

    #This query will return 1 row per asset.  Most of the fields are self explanatory, but scan_count only has the count of
    #unlabled scans or HC Cycle scans.  It does not count the other scan labels.
    #Also be aware that "missed_scan_reason_count" is only valid if scan_count is zero.  It is possible for a missed reason
    #to be supplied if it is supplied before any scans are available (i.e. when scan_count is zero) but if scans come in
    #after it is supplied it will be meaningless.
    #Also -- scan_id is only supplied when it's information should be displayed (i.e. there is a HC Cycle labeled scan that has
    #not been published).  If it is null, and there are unabled scans available (scan_count > hc_cycle_count), the selection
    #list should be shown.

    #The full select is a shell to make dealing with the resuls of the subselect in the from clause easier.
    #By wrapping the group by select in this full select, checking the results of subselect is easier.
    # The real work is done in the subselect.
    period = SwareBase.current_period
    org_id=@org_id.split(',')
    sql = "select * from (
select tool_asset_id as asset_id, host_name, os_product, group_name, ip_string_list, scan_count, missed_scan_reason_count, hc_cycle_count, hc_cycle_released_count, condiction_count,
	case when scan_count = 0 then 'Missing'
		when hc_cycle_count = 0 then 'Unlabeled'
		when hc_cycle_count > hc_cycle_released_count then 'HC Cycle'
		else ''
	end as scan_type,
	case
		when scan_count = 0 and missed_scan_reason_count = 0 then 'Missing, no reason given'
		when scan_count = 0 and missed_scan_reason_count != 0 then 'Missing, reason provided'
		when hc_cycle_count = 0 then 'Available, none labeled'
		when hc_cycle_released_count = 0 then 'Labeled, none released'
		else 'Released'
	end as system_scan_status,
	case when hc_cycle_count > hc_cycle_released_count then (
	  select chs.scan_id
	  from hip_scan_v as chs
	  join dim_comm_tool_asset_scan_hist_v as csh on csh.scan_id = chs.scan_id and csh.scan_service = 'health'
	  where csh.asset_id = assets.tool_asset_id
	  and chs.period_id = #{period.period_id}
	  and chs.publish_ready_timestamp is null)
		else null
	end as scan_id
 -- The following subselect does the real work with a 'group by' to count the various conditions
from (
	select ah.tool_asset_id, ah.host_name, os.os_product, hcg.group_name, ah.ip_string_list,
	count(case when sh.scan_id is null then null else 1 end) as scan_count,
	count(case when ms.missed_scan_id is null then null else 1 end) as missed_scan_reason_count,
	count(case when sh.scan_type = 'HC Cycle' then 1 else null end) as hc_cycle_count,
	count(case when sh.scan_type = 'HC Cycle' and sh.publish_ready_timestamp is not null then 1 else null end) as hc_cycle_released_count,
	count(case
		-- put scan condictions for time and tool here:  when <condiction> then 1 else null
		#{"when 1=1 then 1 else null" if date_range_condition.blank? and scan_tool_condition.blank?}
		#{"when "+date_range_condition+" then 1 else null" if !date_range_condition.blank? and scan_tool_condition.blank?}
    #{"when "+scan_tool_condition + " then 1 else null" if  !scan_tool_condition.blank? and date_range_condition.blank?}
		#{"when "+ date_range_condition + " and "+scan_tool_condition+" then 1 else null" if !date_range_condition.blank? and !scan_tool_condition.blank? }
		end) as condiction_count
	from dim_comm_tool_asset_hist_v as ah
  join dim_comm_os_v as os on os.os_id = ah.os_id
  join hip_asset_group_v as ag on ag.asset_id = ah.tool_asset_id
  join hip_hc_group_v as hcg on hcg.hc_group_id = ag.hc_group_id
  left join (
    select sh1.asset_id, sh1.scan_id, hs1.scan_type, hs1.publish_ready_timestamp, sh1.scan_start_timestamp, t1.manager_name
    from dim_comm_tool_asset_scan_hist_v as sh1
    join dim_comm_tool_v as t1 on t1.tool_id = sh1.tool_id
    left join hip_scan_v as hs1 on hs1.scan_id = sh1.scan_id
    left join hip_ooc_scan_v as ooc on ooc.scan_id = sh1.scan_id
    where sh1.scan_service = 'health'
  	and #{SwareBase.HcCycleAssetFreezeTimestamp.year} = year(sh1.scan_start_timestamp)
  	and #{SwareBase.HcCycleAssetFreezeTimestamp.month} = month(sh1.scan_start_timestamp)
    and sh1.scan_start_timestamp < current_timestamp
  	and (hs1.scan_type is null or hs1.scan_type = 'HC Cycle')
  	and ooc.scan_id is null
    and sh1.SCAN_START_TIMESTAMP < current_timestamp
  ) as sh on sh.asset_id = ah.tool_asset_id
  left join (select * from hip_missed_scan_v where period_id = #{period.period_id}) as ms on ms.asset_id = ah.tool_asset_id
    where ah.org_l1_id =#{org_id[0]} 	and ah.org_id =#{org_id[1]}
    and #{SwareBase.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between ah.row_from_timestamp and coalesce(ah.row_to_timestamp, current_timestamp)
  and hcg.is_current = 'y'	
-- Insert where parts that limit the selected systems here (i.e.:  and os.os_product = 'windows')
  #{"and" unless conditions.blank?}
  #{conditions.join('')}
  group by ah.tool_asset_id, ah.host_name, os.os_product, hcg.group_name, ah.ip_string_list
) as assets
where condiction_count > 0
) as foo-- Sample where clauses
--where scan_count = 0 -- This is the host list for missing scans
--where scan_count = 0 and missed_scan_reason_count = 0 -- This is the host list for missed scans that need reasons assigned
--where scan_count = 0 and missed_scan_reason_count != 0 -- This is the host list for missed scans that have reasons assigned
--where scan_count > 0 and hc_cycle_released_count = 0 -- This is the list of hosts that do not have a released scan
--where hc_cycle_released_count > 0 -- This is the list of hosts that have scans that have been released
--where hc_cycle_released_count < hc_cycle_count -- This is the list of hosts that have scans that could be released
--where system_scan_status = 'Released'
#{"where"  if (!system_scan_status_condition.blank? or !scantype_condition.blank?)}
#{system_scan_status_condition}
#{"and" if (!system_scan_status_condition.blank? and !scantype_condition.blank?)}
#{scantype_condition}
order by host_name"
    sql
  end

  #  def self.org_conditions
  #    id=@org_id.split(',')
  #    ["ah.org_l1_id=#{id[0]} and ah.org_id=#{id[1]}",nil]
  #  end

  def self.hc_group_id_conditions
    ["hcg.hc_group_id = #{@hc_group_id}",nil] unless @hc_group_id.nil? || @hc_group_id.downcase=='all'
  end

  def self.scan_tool_condition
    "sh.manager_name = '#{@scan_tool_id}'" unless @scan_tool_id.downcase=='all'
  end

  def self.date_range_condition
    #["CAST(sh.scan_start_timestamp AS date) BETWEEN '#{@start_date}' AND '#{@end_date}'",nil] unless @start_date.blank? and @end_date.blank?
    "sh.scan_start_timestamp between '#{@start_date} 00:00:00' and '#{@end_date} 23:59:59'" unless @start_date.blank? and @end_date.blank?
  end

  def self.ip_address_conditions
    ["ah.ip_string_list like '%#{@ip_address.strip}%'",nil] unless @ip_address.blank?
  end

  def self.host_name_conditions
    ["lower(ah.host_name) like '%#{@host_name.downcase.strip}%'",nil] unless @host_name.blank?
  end

  def self.os_conditions
    ["os like ?",@os] unless @os.blank?
  end
  def self.system_status_conditions
    ["ah.system_status = 'prod'",nil]
  end
  # should not be included in standard conditions,

  def self.system_scan_status_condition
    case @system_scan_status
    when'no_reason'
      "system_scan_status='Missing, no reason given'"
    when 'with_reason'
      "system_scan_status='Missing, reason provided'"
    when 'available'
      "system_scan_status='Available, none labeled'"
    when 'released'
      "system_scan_status='Released'"
    when 'labeled'
      "system_scan_status='Labeled, none released'"
    when 'missing'
       "system_scan_status in ('Missing, no reason given','Missing, reason provided')"
    when 'incomplete'
      "system_scan_status in ('Available, none labeled','Labeled, none released','Missing, no reason given' ) "
    when "complete"
      "system_scan_status in ('Released','Missing, reason provided' )"
    when "no_hc_cycle_scans"
      #this query is used by the dashboard, column b, # systems with no hc cycle scan.
      "system_scan_status in ('Available, none labeled','Missing, no reason given','Missing, reason provided')"
    end

  end

  def self.scantype_condition

    case @scan_type
    when "missing"
      "scan_type='Missing'"
    when "unlabeled"
      "scan_type='Unlabeled'"
    when "HC Cycle"
      "scan_type='HC Cycle'"
    end
   
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
