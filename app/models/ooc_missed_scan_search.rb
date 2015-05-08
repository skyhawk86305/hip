class OocMissedScanSearch
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

#05-20-2013 Old -  where group.ooc_group_id = #{@params[:ooc_group_id]} and group.ooc_group_type='#{@params[:ooc_group_type]}'

  def sql
    "with system_and_scan_type as (
       select
       group.ooc_group_type,
       group.ooc_group_id,
       type.ooc_scan_type,
       asst.tool_asset_id as asset_id,
       asst.host_name,
       os.os_product,
       group.ooc_group_name,
       asst.ip_string_list,
       asst.system_status
       from hip_ooc_scan_type_v as type
       join hip_ooc_group_v as group on group.ooc_group_type = type.ooc_group_type and ooc_group_status = 'active'
       join hip_ooc_asset_group_v as assg on assg.ooc_group_id = group.ooc_group_id
       join dim_comm_tool_asset_hist_v as asst on asst.tool_asset_id = assg.asset_id
       and asst.org_l1_id = group.org_l1_id
       and asst.org_id = group.org_id
       and current_timestamp between asst.row_from_timestamp and coalesce(asst.row_to_timestamp, current_timestamp)
       and asst.system_status != 'decom'
       join dim_comm_os_v as os on os.os_id = asst.os_id
       where group.ooc_group_id in (#{@group_id_list_str}) and group.ooc_group_type='#{@params[:ooc_group_type]}'
       and type.ooc_scan_type = '#{@params[:ooc_scan_type]}'
       and group.org_l1_id = #{org_l1_id}
       and group.org_id = #{org_id}
       ),
       eligible_scans as (
       -- here we want to produce a list of scans that are available to be used -- either not labeled, or labled for the current group
       -- if unlabled, we only want scans from the last 30 days
       select scan.*                                                          -- scans that are not labeled and in the last 30 days -- eligible scans
       from system_and_scan_type as sst
       join dim_comm_tool_asset_scan_hist_v as scan on scan.asset_id = sst.asset_id
       and scan.scan_service = 'health'
       and scan.scan_start_timestamp between current_timestamp - 31 days and current_timestamp
       left join hip_scan_v as hcscan on hcscan.scan_id = scan.scan_id
       left join hip_ooc_scan_v as oocscan on oocscan.scan_id = scan.scan_id
       where hcscan.scan_id is null
       and oocscan.scan_id is null
       union
       select scan.*                                                          -- scans that are labeled for this ooc_group/ooc_scan_type
       from system_and_scan_type as sst
       join hip_ooc_scan_v as oocscan on oocscan.asset_id = sst.asset_id
       and oocscan.ooc_group_id = sst.ooc_group_id
       and oocscan.ooc_scan_type = sst.ooc_scan_type
       and oocscan.appear_in_dashboard = 'y'
       join dim_comm_tool_asset_scan_hist_v as scan on scan.scan_id = oocscan.scan_id
       ),
       scans as (
       select
       sst.ooc_group_id,
       --sst.ooc_scan_type as scan_type,
       sst.asset_id,
       sst.system_status,
       sst.host_name,
       sst.os_product,
       sst.ooc_group_name group_name,
       sst.ip_string_list,
       tool.manager_name,
       tool.tool_id,
       scan.scan_id,
       --hscan.scan_id as labeled_scan_id,
       missed.ooc_missed_scan_id,
       missed.ooc_scan_type,
       ms.missed_scan_reason,
       ms.missed_scan_reason_id
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
       left join hip_missed_scan_reason_v as ms on ms.missed_scan_reason_id=missed.missed_scan_reason_id
       )
      select * from scans
      where
      #{conditions}
      and scan_id is null"
  end

  def org_conditions
 #   ["ah.org_l1_id=#{org_l1_id} AND ah.org_id=#{org_id}",nil]
  end

  #def group_type_conditions
  #  if not @params[:ooc_group_type].blank? and @params[:ooc_group_id]!='unassigned'
  #    ["ooc_group_type = '#{@params[:ooc_group_type]}'"]
  #  end
  #end

  def scan_type_conditions
   # unless @params[:ooc_scan_type].blank?
    return  ["(ooc_scan_type = '#{@params[:ooc_scan_type]}' or ooc_scan_type is null)"]
    #end
    #if @params[:ooc_scan_type].blank?
    #return  ["ms.ooc_scan_type is null"]
    #end

  end
  
  def ooc_group_id_conditions
    if ! @params[:ooc_group_id].blank? && @params[:ooc_group_id].downcase!='unassigned' and @params[:ooc_group_id].downcase!='assigned'
      ["ooc_group_id = #{@params[:ooc_group_id]}"]
    elsif @params[:ooc_group_id].downcase=='unassigned'
      ["asset_id IS NULL"]
    end
  end

  def system_status_conditions
    if @params[:system_status].blank?
      ["system_status != 'decom'",nil]
    else
      ["system_status = '#{@params[:system_status]}'",nil]
    end
  end

  def os_product_conditions
    ["os_product = '#{@params[:os_product]}'",nil] unless @params[:os_product].blank?
  end

  def host_name_conditions
    ["lower(host_name) LIKE '%#{@params[:host_name].downcase.strip}%'", nil] unless @params[:host_name].blank?
  end

  def ip_string_list_conditions
    ["ip_string_list LIKE '%#{@params[:ip_address].strip}%'"] unless @params[:ip_address].blank?
  end

  def reason_id_conditions
    return ["missed_scan_reason is null"] if  @params[:reason_id].downcase=="unassigned"
    return ["missed_scan_reason_id = #{@params[:reason_id]}"] if @params[:reason_id]!='unassigned' and !@params[:reason_id].blank?
  end

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
end
