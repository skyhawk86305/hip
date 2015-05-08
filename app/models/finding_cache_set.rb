class FindingCacheSet < SwareBase
  
  MAX_CACHE_SET_LIFE = "24 hours"
  
  set_table_name("hip_finding_cache_set_v")
  set_primary_key :cache_set_id
  
  has_many :finding_cache_entries, :order => "row_num", :foreign_key => "cache_set_id"

  before_save :truncate_created_by

  def truncate_created_by
    self.created_by = FindingCacheSet.truncate_userid(self.created_by)
  end

  def self.invalidate_cache(set_type)
    # Need to know:  org_l1_id, org_id, in_cycle?
    (org_l1_id, org_id) = current_org_id.split(',')
    in_cycle = case set_type
    when :incycle then
        "and in_cycle = 'y' "
    when :ooc then
        "and in_cycle = 'n' "
    when :both then
        ""
    else
      RuntimeError "Invalid set_type '#{set_type.to_s}' passed to FindingCacheSet.invalidate_cache"
    end
    
    cycle = 'y'
    sql = "select count(*) as count from final table (
    update #{table_name} set cache_set_status = 'invalid'
    where org_l1_id = #{org_l1_id} and org_id = #{org_id} #{in_cycle}and cache_set_status != 'invalid')"
    find_by_sql(sql)
    true
  end
  
  def self.find_valid_cache_set(org_ids, search_param_hash, set_type)
    (org_l1_id, org_id) = org_ids.split(',')
    in_cycle = case set_type
    when :incycle then
        "and in_cycle = 'y'"
    when :ooc then
        "and in_cycle = 'n'"
    else
      RuntimeError "Invalid set_type '#{set_type.to_s}' passed to FindingCacheSet.find_cache_set"
    end
    cache_set = uncached {
      find(:first, :select => :cache_set_id, 
      :conditions => "cache_set_status = 'valid' and search_param_hash = '#{search_param_hash}'
      #{in_cycle} and org_l1_id = #{org_l1_id} and org_id = #{org_id}",
        :order => "created_at desc")
    }
    return cache_set
  end
  
  def self.invalidate_cache_on_hipmart_update
    sql = "with fact as (
      select org_l1_id, org_id, max(lu_timestamp) as lu_timestamp
      from facts_scan_period_v
      where period_month_id = #{SwareBase.current_month_period_id}
      group by org_l1_id, org_id
    ),
    asset as (
      select org_l1_id, org_id, max(lu_timestamp) as lu_timestamp
      from dim_scan_asset_period_v
      where period_month_id = #{SwareBase.current_month_period_id}
      group by org_l1_id, org_id
    ),
    scan as (
      select org_l1_id, org_id, max(lu_timestamp) as lu_timestamp
      from dim_scan_scan_period_v
      where period_month_id = #{SwareBase.current_month_period_id}
      group by org_l1_id, org_id
    ),
    max_union as (
      select * from fact
      union
      select * from asset
      union
      select * from scan
    ),
    max_change_time as (
      select org_l1_id, org_id, max(lu_timestamp) as lu_timestamp
      from max_union
      group by org_l1_id, org_id
    ),
    cache_set_id as (
      select cs.cache_set_id
      from max_change_time as mt
      join hip_finding_cache_set_v as cs on (cs.org_l1_id, cs.org_id) = (mt.org_l1_id, mt.org_l1_id)
        and cs.cache_set_status = 'valid'
        and cs.in_cycle = 'y'
        and mt.lu_timestamp > cs.created_at
    )
    select count(*) as count from final table (
      update hip_finding_cache_set_v set cache_set_status = 'invalid'
      where cache_set_id in (select csi.cache_set_id from cache_set_id as csi)
    )"
    return find_by_sql(sql)[0][:count]
  end
  
  def self.invalidate_old_cache_sets
    update_all("cache_set_status = 'invalid'", "created_at <= current_timestamp - #{MAX_CACHE_SET_LIFE}")
  end
  
end