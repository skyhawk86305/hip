class OocAssetSearch
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

  def self.inventory(params)
    search_params = new(params)
    search_params.inventory
  end

  def inventory
    result = SwareBase.find_by_sql(sql_inventory)
    return result
  end
  
  def self.inventory_groups(params)
    search_params = new(params)
    search_params.inventory_groups
  end

  def inventory_groups
    result = SwareBase.find_by_sql(sql_inventory_groups)
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

  def group_type_frag
    unless @params[:ooc_group_type].blank?
      "AND grp.ooc_group_type = '#{@params[:ooc_group_type]}'"
    end
  end

  # for Out of Cycle Account Inventory Report
  def sql_inventory
    "SELECT * from DIM_COMM_TOOL_ASSET_HIST_V ah
        join dim_comm_os_v as os on os.os_id = ah.os_id
        where org_l1_id=#{org_l1_id} and org_id=#{org_id}
        AND CURRENT_TIMESTAMP BETWEEN ah.row_from_timestamp AND COALESCE(ah.row_to_timestamp, CURRENT_TIMESTAMP)
        order by host_name"
  end
  # for inventory group assignment report
  def sql_inventory_groups
    "WITH ooc_groups AS
     (
     SELECT assg.asset_id, grp.ooc_group_id as group_id,grp.ooc_group_name as group_name,
     grp.ooc_group_type as group_type, grp.ooc_group_status as group_status
     FROM hip_ooc_asset_group_v AS assg
     JOIN hip_ooc_group_v AS grp ON grp.ooc_group_id = assg.ooc_group_id
     WHERE grp.ooc_group_status != 'deleted'
     AND grp.org_l1_id = #{org_l1_id}
     AND grp.org_id = #{org_id}
     ),
     hc_groups as(
     SELECT assg.asset_id, grp.hc_group_id as group_id,grp.group_name,'hc cycle'as group_type ,
     grp.is_current
     FROM hip_asset_group_v AS assg
     JOIN hip_hc_group_v AS grp ON grp.hc_group_id = assg.hc_group_id
     WHERE  grp.org_l1_id = #{org_l1_id}
     AND grp.org_id = #{org_id}
    ),
    all_groups as (
      select * from ooc_groups
        union
      select * from hc_groups
    )
     SELECT assh.host_name,assh.ip_string_list, assh.hc_start_date,assh.security_policy_name,
     assh.tool_asset_id,os.os_product,assh.system_status,assh.hc_auto_flag,assh.hc_auto_interval_weeks,
     assh.hc_manual_interval_weeks,assh.hc_manual_flag,
    #{group_type_columns_frag}
    CASE
        WHEN assh.hc_auto_flag='y' and assh.hc_manual_flag='y' then 'Yes'
        WHEN assh.hc_auto_flag='n' and assh.hc_manual_flag='n' then 'No'
     ELSE NULL
     END AS hc_required  
    FROM dim_comm_tool_asset_hist_v AS assh
     LEFT join all_groups AS g ON g.asset_id = assh.tool_asset_id
     JOIN dim_comm_os_v AS os ON os.os_id=assh.os_id
     WHERE
     assh.org_l1_id=#{org_l1_id} AND assh.org_id=#{org_id}
     AND CURRENT_TIMESTAMP BETWEEN assh.row_from_timestamp AND COALESCE(assh.row_to_timestamp, CURRENT_TIMESTAMP)
    group by assh.host_name,assh.ip_string_list,assh.hc_start_date,assh.security_policy_name,
     assh.tool_asset_id,os.os_product,assh.system_status,assh.hc_auto_flag, assh.hc_auto_interval_weeks, assh.hc_manual_interval_weeks,
     assh.hc_manual_flag
    ORDER BY assh.host_name"
  end

  def sql
    "WITH groups AS
      (
      SELECT assg.asset_id, grp.ooc_group_id,grp.ooc_group_name,grp.ooc_group_type,
      grp.ooc_group_status, grp.ooc_group_id AS org_ooc_group_id
      FROM hip_ooc_asset_group_v AS assg
      JOIN hip_ooc_group_v AS grp ON grp.ooc_group_id = assg.ooc_group_id
      WHERE grp.ooc_group_status != 'deleted'
        AND grp.org_l1_id = #{org_l1_id}
        AND grp.org_id = #{org_id}
        #{group_type_frag}
      )
      SELECT assh.host_name,assh.ip_string_list, assh.hc_start_date,assh.security_policy_name,
            assh.tool_asset_id,grp.ooc_group_id,grp.ooc_group_type,grp.ooc_group_status,
            os.os_product,assh.system_status,grp.org_ooc_group_id,grp.ooc_group_name,
            CASE
              WHEN assh.hc_auto_flag='y' and assh.hc_manual_flag='y' then 'Yes'
              WHEN assh.hc_auto_flag='n' and assh.hc_manual_flag='n' then 'No'
              ELSE NULL
            END AS hc_required,
            'n' as selected
      FROM dim_comm_tool_asset_hist_v AS assh
      LEFT join groups AS grp ON grp.asset_id = assh.tool_asset_id
      JOIN dim_comm_os_v AS os ON os.os_id=assh.os_id
      WHERE
        #{conditions}
      AND CURRENT_TIMESTAMP BETWEEN assh.row_from_timestamp AND COALESCE(assh.row_to_timestamp, CURRENT_TIMESTAMP)
      ORDER BY assh.host_name"
  end

  def org_conditions
    ["assh.org_l1_id=#{org_l1_id} AND assh.org_id=#{org_id}",nil]
  end

  def group_status_conditions
    ["grp.ooc_group_status = '#{@params[:ooc_group_status]}'",nil] unless @params[:ooc_group_status].blank?
  end
  def group_type_conditions
    if not @params[:ooc_group_type].blank? and @params[:ooc_group_id]!='unassigned'
      ["grp.ooc_group_type = '#{@params[:ooc_group_type]}'",nil]
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
    if @params[:system_status].blank?
      ["assh.system_status != 'decom'",nil]
    else
      ["assh.system_status = '#{@params[:system_status]}'",nil]
    end
  end

  def os_product_conditions
    ["assh.os_id=os.os_id AND os.os_product = '#{@params[:os_product]}'",nil] unless @params[:os_product].blank?
  end

  def host_name_conditions
    ["lower(assh.host_name) LIKE '%#{@params[:host_name].downcase.strip}%'", nil] unless @params[:host_name].blank?
  end
  def ip_string_list_conditions
    ["assh.ip_string_list LIKE '%#{@params[:ip_string_list].strip}%'",nil] unless @params[:ip_string_list].blank?
  end

  def hc_sec_class_conditions
    ["assh.security_policy_name = '#{@params[:hc_sec_class]}'", nil] unless @params[:hc_sec_class].blank?
  end

  def hc_required_conditions
    unless @params[:hc_required].blank?
      if @params[:hc_required]=='Yes'
        return [" (hc_auto_flag = 'y' and hc_manual_flag = 'y')",nil]
      end
      if @params[:hc_required]=='No'
        return [" (hc_auto_flag = 'n' AND hc_manual_flag = 'n')",nil]
      end
    end
  end

  def group_type_columns_frag
    group_types = OocGroupType.all
    group_types.map!{|t| t.ooc_group_type}.insert(0,"hc cycle")

    frag = []

    group_types.each do |type|
      $stderr.puts type
      frag.push("max(case when g.group_type = '#{type.downcase}' then g.group_name else null end) as #{type.downcase.gsub(" ","_")},\n")
      frag.push("max(case when g.group_type = '#{type.downcase}' then g.group_status else null end) as #{type.downcase.gsub(" ","_")}_status,\n")
    end
    return frag
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
