class OocScan < SwareBase

  set_table_name("hip_ooc_scan_v")
  set_primary_keys :scan_id

  belongs_to :asset_scan, :primary_key=>:scan_id, :foreign_key => :scan_id
  belongs_to :ooc_group
  belongs_to :org, :primary_key=>[:org_l1_id,:org_id], :foreign_key =>[:org_l1_id,:org_id]

  before_save :set_lu_data
  before_save :invalidate_deviation_search_cache_ooc
  before_destroy :invalidate_deviation_search_cache_ooc
  # :period

  # This override of delete_all is needed since delete_all does not call any of the defined callbacks
  # Note also that the super method will not work in this case since it is dynamically assoicated
  # with methods
  def self.delete_all(conditions = nil)
    invalidate_deviation_search_cache_ooc
    sql = "DELETE FROM #{quoted_table_name} "
    add_conditions!(sql, conditions, scope(:find))
    connection.delete(sql, "#{name} Delete all")
  end

  def self.create_all!(scans,lu_userid)
    # Expects scan_findings to be an array of hashes to be used for create, or a simple hash for create
    # In the array, all hashes must have the same set of keys
    invalidate_deviation_search_cache_ooc
    if ! scans.respond_to?('[]')
      create! scans
    else
      size = scans.size
      current = 0
      increment = 500
      while current < size
        insert = create_multiple_insert(scans[current, increment],lu_userid)
        OocScan.connection.execute(insert)
        current += increment
      end
    end
  end

  # Note:  The two over ridden methods below, override methods in composit_keys.  They have
  # been modified to supply the second "false" parameter to attriburtes_with_quotes.  This
  # causes the "attr_readonly" to be ignored for both create and update
  private


  def self.create_multiple_insert(scans,lu_userid)
    #scan_findings must be an array os scan_id
    result = "with release_scans (scan_id) as (values"
    insert_value_string=""
    scans.each do |s|
      insert_value_string << "(#{s})"
      insert_value_string << ","
    end
    insert_value_string[-1] = ')'
   # insert_value_string << ','
    insert_value_string << "
      select * from final table
      (update hip_ooc_scan_v set publish_ready_timestamp = current_timestamp,
      lu_userid = '#{lu_userid[0...columns_hash["lu_userid"].limit]}',publish_ready_userid='#{lu_userid[0...columns_hash["lu_userid"].limit]}', lu_timestamp = current_timestamp where scan_id in
      (select scan_id from  release_scans))"
    result << insert_value_string
    result
  end

  def self.find_latest_scan(asset_ids, ooc_group_id, options ={})
    return [] if asset_ids.empty?
    default_options = {
      :org_id => current_org_id,
    }
    options = default_options.merge(options)
    asset_ids.compact!
    org_id = options[:org_id].split(',').map {|o| o.to_i}

    sql = "-- OocScan.find_latest_scan
    with asset_ids (asset_id) as (values
      #{asset_ids.join(',')}
    ),
    possible_scans as (
      select s.scan_id, s.asset_id, s.scan_start_timestamp
      from asset_ids as a
      join hip_ooc_asset_group_v as ag on ag.asset_id = a.asset_id
           and ag.ooc_group_id = #{ooc_group_id}
      join dim_comm_tool_asset_scan_hist_v as s on s.asset_id = a.asset_id
        and s.scan_service = 'health'
      where s.org_l1_id = #{org_id[0]}
      and date(s.scan_start_timestamp) between current_date - 31 days and current_date
    ),
    used_scans as (
      select s.scan_id
      from possible_scans as ps
      join hip_scan_v as s on s.scan_id = ps.scan_id
      union
      select s.scan_id
      from possible_scans as ps
      join hip_ooc_scan_v as s on s.scan_id = ps.scan_id
    ),
    unused_scans as (
      select ps.scan_id, ps.asset_id, ps.scan_start_timestamp
      from possible_scans as ps
      left join used_scans as us on us.scan_id = ps.scan_id
      where us.scan_id is null
    )
    select uus.scan_id
    from unused_scans as uus
    where scan_start_timestamp = (select max(uus1.scan_start_timestamp) from unused_scans as uus1 where uus1.asset_id = uus.asset_id)
    "
    query_result = SwareBase.find_by_sql(sql)
    return query_result.map {|a| a.scan_id}
  end
  

  def self.label_scans(scan_ids, ooc_group_id, ooc_scan_type, options = {})
    return true if scan_ids.empty?
    default_options = {
      :lu_userid => user_id, :org_id => current_org_id,
    }
    options = default_options.merge(options)
    scan_ids.compact!
    # Use single SQL statement to label the scan_ids supplied only if the asset
    # does not have a scan already labeled for this period
    scan_ids.map! {|s| s.to_i}
    org_id = options[:org_id].split(',').map {|o| o.to_i}
    sql = "-- OocScan.label_scans
    with scan_ids (scan_id) as (values
      #{scan_ids.join(',')}
   ),
    asset_ids as (
      select distinct s.asset_id
      from dim_comm_tool_asset_scan_hist_v as s
      join scan_ids as si on si.scan_id = s.scan_id
      where s.org_l1_id = #{org_id[0]}
    ),
    existing_labeled as (
      -- Get the scans that are already labeled for the assets derived from the scan list
      select s.scan_id, s.asset_id
      from hip_ooc_scan_v as s
      join asset_ids as ai on ai.asset_id = s.asset_id
      where s.ooc_group_id = #{ooc_group_id}
        and s.ooc_scan_type = #{quote_value(ooc_scan_type)}
        and publish_ready_timestamp is null
      union
      -- Get the scans from the list that are already labeled as HC Cycle
      select si1.scan_id, s1.asset_id
      from scan_ids as si1
      join hip_scan_v as hs1 on hs1.scan_id = si1.scan_id
      join dim_comm_tool_asset_scan_hist_v as s1 on s1.scan_id = si1.scan_id
      -- Get the scans from the list that are already labeled as OOC
      union
      select si2.scan_id, hos2.asset_id
      from scan_ids as si2
      join hip_ooc_scan_v as hos2 on hos2.scan_id = si2.scan_id
    ),
    no_existing_label as (
      -- Remove the scans that are already used, or have assets that have labeled but unreleased scans
      select s.*, t.tool_name
      from dim_comm_tool_asset_scan_hist_v as s
      join scan_ids as si on si.scan_id = s.scan_id
      join dim_comm_tool_v as t on t.tool_id = s.tool_id
      left join existing_labeled as el on el.asset_id = s.asset_id
      where el.scan_id is null
      and (org_l1_id, org_id) = (#{org_id.join(',')})
    )
    -- Create the records which will label the scans
    select count(*) as count from final table (
      insert into hip_ooc_scan_v (scan_id, org_l1_id, org_id, ooc_group_id, asset_id, tool_id, tool_name, ooc_scan_type,
        scan_start_timestamp, lu_userid, lu_timestamp)
      select scan_id, #{org_id.join(',')}, #{ooc_group_id}, asset_id, tool_id, tool_name, #{quote_value(ooc_scan_type)},
        scan_start_timestamp, #{quote_value(options[:lu_userid][0...columns_hash["lu_userid"].limit])}, current_timestamp
      from no_existing_label
    )"
    find_by_sql(sql)
    return true
  end

end
