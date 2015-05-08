class AssetGroup < SwareBase
  set_table_name("hip_asset_group_v")
  set_primary_keys [:hc_group_id,:asset_id]

  has_one :asset, :primary_key =>:tool_asset_id,  :foreign_key => [:hc_group,:asset_id]
  belongs_to :hc_group,:primary_key=> :hc_group_id, :foreign_key => :hc_group_id
  
  before_save :set_lu_data
  before_save :invalidate_deviation_search_cache_incycle
  before_destroy :invalidate_deviation_search_cache_incycle

  named_scope :production ,:joins=>"join dim_comm_tool_asset_hist_v as ah on ah.tool_asset_id=hip_asset_group_v.asset_id",
    :conditions=>"ah.system_status='prod' and #{AssetGroup.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)}
            between ah.row_from_timestamp and
            coalesce(ah.row_to_timestamp,current_timestamp)"

  # This override of delete_all is needed since delete_all does not call any of the defined callbacks
  # Note also that the super method will not work in this case since it is dynamically assoicated
  # with methods
  def self.delete_all(conditions = nil)
    invalidate_deviation_search_cache_incycle
    sql = "DELETE FROM #{quoted_table_name} "
    add_conditions!(sql, conditions, scope(:find))
    connection.delete(sql, "#{name} Delete all")
  end
  
  def self.create_all!(assets)
    # Expects assets to be an array of hashes to be used for create, or a simple hash for create
    # In the array, all hashes must have the same set of keys
    if ! assets.respond_to?('[]')
      create! assets
    else
      size = assets.size
      current = 0
      increment = 500
      while current < size
        insert = create_multiple_insert(assets[current, increment])
        self.connection.execute(insert)
        current += increment
      end
    end
  end
   
  private

  def self.create_multiple_insert(assets)
    #scan_findings must be an array of hashes, all hashes must have the same set of keys
    keys = assets[0].keys
    result = "INSERT INTO #{table_name} (lu_timestamp, #{keys.join(', ')}) values "
    assets.each do |sf|
      insert_value_string = "(current_timestamp, "
      keys.each do |column|
        if column.to_s == "lu_userid"   # Note:  Do not generalize this test, we only want to truncate userids
          insert_value_string << quote_value(sf[column][0...columns_hash["lu_userid"].limit])
        else
          insert_value_string << quote_value(sf[column])
        end
        insert_value_string << ","
      end
      insert_value_string[-1] = ')'
      insert_value_string << ','
      result << insert_value_string
    end
    result.chop!
    result
  end
end
