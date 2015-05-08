class MissedScanSearch

  attr_accessor :hc_group_id,:per_page,:host_name,:ip_address,:org_id,:reason_id
  @@per_page=10

  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end

  #query for a list of assets
  def self.search(params)
    @hc_group_id=params['hc_group_id']
    @ip_address=params['ip_address']
    @host_name=params['host_name']
    @org_id=params['org_id']
    @reason_id=params['reason_id']

    @sort=params['sort']
    find_missed_scans
  end

  # get cout of unexplained missed scans for dashboard
  def self.count_missed_scan_unexplained(org)
    id=org.id.to_s.split(',')
    sql = "select count(*) as count
    from dim_comm_tool_asset_hist_v as ah
    left join (select * from dim_comm_tool_asset_scan_hist_v where year(scan_start_timestamp) = year(current_timestamp) and month(scan_start_timestamp) = month(current_timestamp) and scan_service = 'health') as sh on sh.asset_id = ah.tool_asset_id
    join hip_asset_group_v as ag on ag.asset_id = ah.tool_asset_id
    join hip_hc_group_v as hg on hg.hc_group_id = ag.hc_group_id
    left join hip_missed_scan_v as ms on ms.asset_id = ah.tool_asset_id
    where (select asset_freeze_timestamp from hip_period_v where month_of_year = month(current_timestamp) and year = year(current_timestamp) and org_l1_id = 0 and org_id = 0) between ah.row_from_timestamp and coalesce(ah.row_to_timestamp, current_timestamp)
    and ah.org_l1_id = #{id[0]} and ah.org_id = #{id[1]}
    and sh.asset_id is null
    and hg.is_current = 'y'
    and ms.asset_id is null"
    return Asset.find_by_sql(sql)[0][:count]
  end
  private

  # query for paination for review
  def self.find_missed_scans
    id = @org_id.split(',')

    sql = "select ah.*, 
    hg.group_name as group_name, 
    os.os_product,ms.missed_scan_id as missed_scan_id, 
    ms.missed_scan_reason_id,
    CASE WHEN msr.missed_scan_reason is null THEN 'Not Specified Yet' ELSE msr.missed_scan_reason END as missed_scan_reason
    from dim_comm_tool_asset_hist_v as ah
    join hip_asset_group_v as ag on ag.asset_id = ah.tool_asset_id
    join hip_hc_group_v as hg on hg.hc_group_id = ag.hc_group_id
    join dim_comm_os_v as os on os.os_id = ah.os_id
    left join (select ascan.asset_id 
    from dim_comm_tool_asset_scan_hist_v as ascan
    left join hip_ooc_scan_v as oscan on oscan.scan_id = ascan.scan_id
    where year(ascan.scan_start_timestamp) = year(current_timestamp) 
    and month(ascan.scan_start_timestamp) = month(current_timestamp) 
    and ascan.scan_service = 'health'
    and oscan.scan_id is null) as sh on sh.asset_id = ah.tool_asset_id
    left join hip_missed_scan_v as ms on ms.asset_id = ah.tool_asset_id 
    and ms.period_id=#{SwareBase.current_period_id}
    left join hip_missed_scan_reason_v as msr on msr.missed_scan_reason_id = ms.missed_scan_reason_id
    where #{SwareBase.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between ah.row_from_timestamp and coalesce(ah.row_to_timestamp, current_timestamp)
    and ah.org_l1_id = #{id[0].to_i} and ah.org_id = #{id[1].to_i}
    and sh.asset_id is null
    and hg.is_current = 'y'"
    sql.concat(" AND ") unless conditions.join('').blank?
    sql.concat(" #{conditions.join('')}")
    sql.concat(" ORDER BY ah.host_name")

    return Asset.find_by_sql(sql)
  end

  def self.system_status_conditions
    ["ah.system_status='prod'",nil]
  end

  def self.hc_group_id_conditions
    ["hg.hc_group_id = #{@hc_group_id}",nil] unless @hc_group_id.downcase=='all'
  end

  def self.host_name_conditions
    ["lower(ah.host_name) like '%#{@host_name.downcase.strip}%'",nil] unless @host_name.blank?
  end

  def self.ip_address_conditions
    ["ah.ip_string_list like '%#{@ip_address.strip}%'",nil] unless @ip_address.blank?
  end

  def self.reason_id_conditions
      return ["ms.asset_id is null", nil] if  @reason_id.downcase=="unassigned"
      return ["ms.missed_scan_reason_id = #{@reason_id}"] if @reason_id!='unassigned' and @reason_id.downcase!="all"
  end

  def self.conditions
    [conditions_clauses.join(' AND '), *conditions_options]
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
end
