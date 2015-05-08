class Scan < SwareBase

  set_table_name("hip_scan_v")
  set_primary_keys :scan_id

  has_one :asset_scan, :primary_key=>:scan_id, :foreign_key => :scan_id

  before_save :set_lu_data
  before_save :invalidate_deviation_search_cache_incycle
  before_destroy :invalidate_deviation_search_cache_incycle
  # :period

  # This override of delete_all is needed since delete_all does not call any of the defined callbacks
  # Note also that the super method will not work in this case since it is dynamically assoicated
  # with methods
  def self.delete_all(conditions = nil)
    invalidate_deviation_search_cache_incycle
    sql = "DELETE FROM #{quoted_table_name} "
    add_conditions!(sql, conditions, scope(:find))
    connection.delete(sql, "#{name} Delete all")
  end
    
 def self.create_all!(scans,lu_userid,period_id)
    # Expects scan_findings to be an array of hashes to be used for create, or a simple hash for create
    # In the array, all hashes must have the same set of keys
    if ! scans.respond_to?('[]')
      create! scans
    else
      size = scans.size
      current = 0
      increment = 500
      while current < size
        insert = create_multiple_insert(scans[current, increment],lu_userid,period_id)
        Scan.transaction do
          Scan.connection.execute(insert)
        end
        current += increment
      end
    end
  end


  private

  def self.create_multiple_insert(scans,lu_userid,period_id)
    #scan_findings must be an array os scan_id
    result = "with release_scans (scan_id) as (values "
    insert_value_string=""
    scans.each do |s|
      insert_value_string << "(#{s})"
      insert_value_string << ","
    end
    insert_value_string[-1] = ')'
   # insert_value_string << ','
    insert_value_string << "
      select * from final table (update hip_scan_v set publish_ready_timestamp = current_timestamp,
      publish_ready_userid='#{lu_userid[0...columns_hash["lu_userid"].limit]}',
      lu_userid = '#{lu_userid[0...columns_hash["lu_userid"].limit]}', lu_timestamp = current_timestamp where period_id = #{period_id}
      and scan_id in (select scan_id from  release_scans))"
    result << insert_value_string
    result
  end

  def self.label_scans(scan_ids, options = {})
    default_options = {:period_id => HipPeriod.current_period.first.id,
      :scan_type => 'HC Cycle',
      :lu_userid => user_id, :org_id => current_org_id,
    }
    options = default_options.merge(options)
    scan_ids.compact!
    # Use single SQL statement to label the scan_ids supplied only if the asset
    # does not have a scan already labeled for this period
    scan_ids.map! {|s| s.to_i}
    period_id = options[:period_id].to_i
    org_id = options[:org_id].split(',').map {|o| o.to_i}
    sql = "-- Scan.label_scans
    with scan_ids (scan_id) as (values
      #{scan_ids.join(',')}
    ),
    asset_ids as (
      select distinct s.asset_id
      from dim_comm_tool_asset_scan_hist_v as s
      join scan_ids as si on si.scan_id = s.scan_id
    ),
    existing_labeled as (
      -- Get the scans that are already labeled for the assets derived from the scan list
      select hs.scan_id, s.asset_id
      from hip_scan_v as hs
      join dim_comm_tool_asset_scan_hist_v as s on s.scan_id = hs.scan_id
        and s.org_l1_id = #{org_id[0]}
      join asset_ids as ai on ai.asset_id = s.asset_id
      where hs.period_id = #{period_id}
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
      select s.*
      from dim_comm_tool_asset_scan_hist_v as s
      join scan_ids as si on si.scan_id = s.scan_id
      left join existing_labeled as el on el.asset_id = s.asset_id
      where el.scan_id is null
      and (s.org_l1_id, s.org_id) = (#{org_id.join(',')})
      and s.scan_service = 'health'
    )
    -- Create the records which will label the scans
    select count(*) as count from final table (
      insert into hip_scan_v (scan_id, period_id, scan_type, lu_userid, lu_timestamp)
      select scan_id, #{SwareBase.current_period_id}, #{quote_value(options[:scan_type])}, #{quote_value(options[:lu_userid][0...columns_hash["lu_userid"].limit])},
        current_timestamp from no_existing_label
    )"
    find_by_sql(sql)
  end

end
