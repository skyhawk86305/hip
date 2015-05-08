class AssetSearch

  attr_accessor :hc_group_id, :system_status,:os_product,:host_name,:ip_string_list,
    :org_id,:hc_group_name,:sort, :hc_sec_class, :hc_interval, :hc_required

  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end
  
  # query for a list of assets
  def self.assets(params)
    @hc_group_id=params['hc_group_id']
    @system_status=params['system_status']
    @os_product=params['os_product']
    @host_name=params['host_name']
    @ip_string_list=params['ip_string_list']
    @org_id=params['org_id']
    @hc_interval=params['hc_interval']
    @hc_sec_class=params['hc_sec_class']
    @hc_required=params['hc_required']
    @sort=params['sort']
    @is_current=params['is_current']
    find_assets
  end

  # get a list of assets for update
  def self.update_assets(params)
    @hc_group_id=params['hc_group_id']
    @system_status=params['system_status']
    @os_product=params['os_product']
    @host_name=params['host_name']
    @ip_string_list=params['ip_string_list']
    @org_id=params['org_id']
    find_assets_for_update
  end

  # used for he executive dashboard report
  # and the Account Dahsboard.
  def self.executive_report(org_id)
    (l1id, id) = org_id.split(',')
    sql="select org.org_name, hg.group_name, hg.is_current, asset.* 
          from dim_comm_tool_asset_hist_v asset
          LEFT JOIN hip_asset_group_v ag ON ag.asset_id = asset.tool_asset_id
          LEFT JOIN hip_hc_group_v as hg on hg.hc_group_id=ag.hc_group_id
          join dim_comm_org_v as  org on org.org_l1_id = asset.org_l1_id and org.org_id=asset.org_id
          where
            #{SwareBase.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between asset.row_from_timestamp and
            coalesce(asset.row_to_timestamp,current_timestamp)
          and org.org_l1_id=#{l1id} and org.org_id=#{id}
          and asset.system_status='prod'
          order by org.org_name"
    Asset.find_by_sql sql
  end

  def self.inventory_detail_report(org_id)

    (l1id, id) = org_id.split(',')
    sql="select asset.*, os.os_product, hg.group_name,hg.hc_group_id, hg.is_current,  msr.missed_scan_reason
          from dim_comm_tool_asset_hist_v asset
          LEFT JOIN hip_asset_group_v ag ON ag.asset_id = asset.tool_asset_id
          LEFT JOIN dim_comm_os_v os on os.os_id=asset.os_id
          left join hip_missed_scan_v as ms on ms.asset_id = asset.tool_asset_id and ms.period_id = #{SwareBase.current_period_id}
          left join hip_missed_scan_reason_v msr on msr.missed_scan_reason_id=ms.missed_scan_reason_id
          LEFT JOIN hip_hc_group_v as hg on hg.hc_group_id=ag.hc_group_id
            join dim_comm_org_v as  org on org.org_l1_id = asset.org_l1_id and org.org_id=asset.org_id
          where
            #{AssetScan.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)}
            between asset.row_from_timestamp and
            coalesce(asset.row_to_timestamp,current_timestamp)
          and org.org_l1_id=#{l1id} and org.org_id=#{id}
          order by asset.host_name"
    Asset.find_by_sql sql
  end
  private

  # query for paination for review
  def self.find_assets
    org = Org.find(@org_id)
    org.assets.find :all,:select=>"dim_comm_tool_asset_hist_v.*,hg.hc_group_id,hg.group_name,os.os_product,'' selected", :conditions => conditions, :order=>"host_name #{@sort}", :joins=> include_condition
  end

  # query without pagination for updates
  def self.find_assets_for_update
    org = Org.find(@org_id)
    org.assets :conditions => conditions, :joins=>include_condition
  end

  def self.include_condition
    include = []
    #include.push "asset_groups"
    include.push(" LEFT JOIN hip_asset_group_v as ag ON ag.asset_id = dim_comm_tool_asset_hist_v.tool_asset_id ")
    include.push(" LEFT JOIN dim_comm_os_v as os on os.os_id=dim_comm_tool_asset_hist_v.os_id")# unless @os_product.blank?
    include.push(" LEFT JOIN hip_hc_group_v as hg on hg.hc_group_id=ag.hc_group_id")# unless @is_current.blank?
   # include.push(" LEFT JOIN dim_comm_tool_asset_hist_v as ah ON ah.tool_asset_id = ag.asset_id ")
    include
  end

  def self.hip_period_conditions
    ["(select asset_freeze_timestamp from hip_period_v
    where month_of_year=month(current_timestamp)
    and year=year(current_timestamp)  and org_l1_id=0 and org_id=0)
    between dim_comm_tool_asset_hist_v.row_from_timestamp and 
    coalesce(dim_comm_tool_asset_hist_v.row_to_timestamp,current_timestamp)"]
  end

  def self.hc_group_id_conditions
    if ! @hc_group_id.blank? && @hc_group_id.downcase!='unassigned'
      ["ag.hc_group_id = #{@hc_group_id}"]
    elsif @hc_group_id.downcase=='unassigned'
      ["ag.hc_group_id is null"]
    end

  end

  def self.system_status_conditions
    if @system_status.blank?
      #default only show prod status
      ["system_status = ?", 'prod'] 
    elsif @system_status!='all'
      ["system_status = ?", @system_status]
    end
  end

  def self.os_product_conditions
    ["dim_comm_tool_asset_hist_v.os_id=os.os_id and os.os_product = ?", "#{@os_product}"] unless @os_product.blank?
  end

  def self.host_name_conditions
    ["lower(host_name) LIKE ?", "%#{@host_name.downcase.strip}%"] unless @host_name.blank?
  end
  def self.ip_string_list_conditions
    ["ip_string_list LIKE ?", "%#{@ip_string_list}%"] unless @ip_string_list.blank?
  end

  def self.is_current_conditions
    [" hg.is_current = ?", @is_current] unless @is_current.blank?
  end

  def self.hc_interval_conditions
    [" hc_auto_interval_weeks = ?", @hc_interval] unless @hc_interval.blank?
  end
  
  def self.hc_sec_class_conditions
    [" security_policy_name = ?", @hc_sec_class] unless @hc_sec_class.blank?
  end
  
  def self.hc_required_conditions
    unless @hc_required.blank?
      if @hc_required=='Yes'
        return [" (hc_auto_flag = ? or hc_manual_flag = ?)",'y','y']
      end
      if @hc_required=='No'
        return [" (hc_auto_flag = ? and hc_manual_flag = ?)",'n','n']
      end
    end
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
    AssetSearch.methods.grep(/_conditions$/).map { |m| send(m) }.compact
  end

end
