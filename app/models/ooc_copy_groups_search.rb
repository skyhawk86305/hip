class OocCopyGroupsSearch
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

  def target_group_type
    OocGroup.find(@params[:group_target]).ooc_group_type
  end

  def source_group_type
    @params[:group_src].split(',')[1]
  end
  def source_group_id
    @params[:group_src].split(',')[0]
  end

  def source_ids_exp
    if source_group_type=='HC Cycle'
      return "select asset_id,hc_group_id as group_id from hip_asset_group_v
       where hc_group_id=#{source_group_id}"
    else
      return "select asset_id,ooc_group_id as group_id from hip_ooc_asset_group_v
       where ooc_group_id=#{source_group_id}"
    end
  end
  def sql
        "with source_ids as (
        #{source_ids_exp}
      ),
      in_other_ooc_group as (
      -- system in source_ids, not in target group , but in other ooc group of same type
      -- search for not in target and in group of target group type.
      select s.asset_id,g.ooc_group_id from source_ids s
      left join hip_ooc_asset_group_v as ag on ag.asset_id=s.asset_id
      join hip_ooc_group_v as g on g.ooc_group_id=ag.ooc_group_id
      where g.ooc_group_status!='deleted'
      and g.ooc_group_type = '#{target_group_type}' and g.ooc_group_id != #{@params[:group_target]}
      ),
      in_target_group as (
      select s.asset_id,ag.ooc_group_id from source_ids s
      left join hip_ooc_asset_group_v as ag on ag.asset_id=s.asset_id
      where ooc_group_id=#{@params[:group_target]}
      ),
      -- Tells what needs to be done
      actions as (
      select
      coalesce(s.asset_id, t.asset_id) as asset_id,
      case
       when s.asset_id is null then 'delete'
       when g.asset_id is null and t.asset_id is null then 'copy'
       when g.asset_id is null and t.asset_id is not null then 'nothing'
       when g.asset_id is not null and t.asset_id is null then 'move'  -- we need the name of the from group
       else 'error'
       end as action_code,
      oocg.ooc_group_name,
      oocg.ooc_group_type,
      g.ooc_group_id
      from source_ids as s
      left join in_other_ooc_group as g on g.asset_id = s.asset_id
      full outer join in_target_group as t on t.asset_id = s.asset_id
      left join hip_ooc_group_v as oocg on oocg.ooc_group_id=g.ooc_group_id
      )
      select
      a.asset_id,
      a.action_code,
      a.ooc_group_name,
      a.ooc_group_type,
      a.ooc_group_id,
      ah.host_name,
      ah.ip_string_list,
      ah.system_status,
      os.os_product
      from actions as a
      join dim_comm_tool_asset_hist_v ah on ah.tool_asset_id=a.asset_id
        and CURRENT_TIMESTAMP BETWEEN ah.row_from_timestamp AND
        COALESCE(ah.row_to_timestamp, CURRENT_TIMESTAMP) and ah.system_status!='decom'
      join dim_comm_os_v as os on os.os_id=ah.os_id
          order by ah.host_name"
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
