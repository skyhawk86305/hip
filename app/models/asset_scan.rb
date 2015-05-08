class AssetScan < SwareBase

  attr_accessor :ready_to_publish

  set_table_name("dim_comm_tool_asset_scan_hist_v")
  set_primary_keys [:asset_id,:tool_id,:scan_stop_timestamp]

  belongs_to :tool
  belongs_to :asset, :primary_key=>:tool_asset_id, :foreign_key=> :asset_id
  belongs_to :scan #, :primary_key=>:scan_id,:foreign_key=>:scan_id
  belongs_to :org, :primary_key=>[:org_l1_id,:org_id] ,:foreign_key=> [:org_l1_id,:org_id]
  belongs_to :fact_scan,:primary_key=>:asset_id, :foreign_key=>:asset_id
  before_save :set_lu_data
end
