class HcGroupSearch < SwareBase
  
  class HcGroupSearchException < Exception 
  end
  
  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end

  def self.search(params)
    org_id = params[:org_id]
    hc_group_name = params[:hc_group_name]
    sort_direction = params[:sort_direction] || "asc"
    
    org_id = org_id.join(',') if org_id.respond_to?(:join)
    
    raise(HcGroupSearchException, ":sort_direction must be either 'asc' or 'desc'") unless sort_direction == "asc" || sort_direction == "desc"
    raise(HcGroupSearchException, "Invalid :org_id") unless org_id =~ /^\d+,\d+$/
    
    group_name_condition = hc_group_name ? "and lower(group_name) like '%#{hc_group_name.downcase}%'" : ''
    
    sql = "select g.group_name, g.hc_group_id, g.is_current, g.last_current_timestamp, count(a.tool_asset_id) as asset_count
      from hip_hc_group_v as g
      left join hip_asset_group_v as ag on ag.hc_group_id = g.hc_group_id
      left join dim_comm_tool_asset_hist_v as a on a.tool_asset_id = ag.asset_id
      and ? between a.row_from_timestamp and coalesce(a.row_to_timestamp, current_timestamp)
      and a.system_status = 'prod'
      where (g.org_l1_id, g.org_id) = (#{org_id}) #{group_name_condition}
      group by g.group_name, g.hc_group_id, g.is_current, g.last_current_timestamp
      order by g.group_name #{sort_direction}"
    
    return SwareBase.find_by_sql([sql, SwareBase.HcCycleAssetFreezeTimestamp])
  end
  
end    