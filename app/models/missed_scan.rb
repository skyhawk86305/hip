
class MissedScan < SwareBase
 
  set_table_name("hip_missed_scan_v")
  set_primary_key :missed_scan_id
 
  before_save :set_lu_data
  
  belongs_to :MissedScanReason
  belongs_to :asset,:primary_key=>:tool_asset_id, :foreign_key=>:asset_id
  belongs_to :hip_period,:primary_key=>:period_id, :foreign_key=>:period_id

   def self.create_all!(assets)
    # Expects scan_findings to be an array of hashes to be used for create, or a simple hash for create
    # In the array, all hashes must have the same set of keys
    if ! assets.respond_to?('[]')
      create! assets
    else
      size = assets.size
      current = 0
      increment = 500
      while current < size
        insert = create_multiple_insert(assets[current, increment])
        MissedScan.transaction do
          MissedScan.connection.execute(insert)
        end
        current += increment
      end
    end
  end

  # Note:  The two over ridden methods below, override methods in composit_keys.  They have
  # been modified to supply the second "false" parameter to attriburtes_with_quotes.  This
  # causes the "attr_readonly" to be ignored for both create and update
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
