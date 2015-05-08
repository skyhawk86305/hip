class Asset < SwareBase

  attr_writer :hc_group_id

  set_table_name("dim_comm_tool_asset_hist_v")
  set_primary_keys :tool_asset_id
  belongs_to :hc_group
  belongs_to :tool
  belongs_to :os
  belongs_to :org,:primary_key=>[:org_l1_id,:org_id], :foreign_key =>[:org_l1_id,:org_id]

  has_one :asset_group, :primary_key =>[:hc_group_id,:asset_id] , :foreign_key =>:asset_id
  has_many :asset_scans, :primary_key=>[:asset_id,:tool_id,:scan_stop_timestamp], :foreign_key => :asset_id
  #has_many :scan_findings, :primary_key=>[:asset_id,:period_id,:finding_id], :foreign_key=>:asset_id
  # has_many :hip_exceptions,:primary_key=>:suppress_id,:foreign_key=>:asset_id
  has_many :missed_scan ,:primary_key=>:missed_scan_id,:foreign_key=>:asset_id

  before_save :set_lu_data
  
  named_scope :status_for_select, :select=>"DISTINCT system_status", :conditions=>"system_status !='decom'"
  named_scope :sec_class_list, :select=>"DISTINCT security_policy_name", :conditions=>'security_policy_name is not null'
  named_scope :interval_list, :select=>"DISTINCT hc_auto_interval_weeks" , :conditions=>'hc_auto_interval_weeks is not null'
  named_scope :current, :conditions => "current_timestamp between row_from_timestamp and coalesce(row_to_timestamp, current_timestamp)"
  
  #def hc_group_id
  #  a = AssetGroup.find_by_asset_id(self.id)
  #  a.hc_group_id unless a.blank?
  #end

  def hc_group_id=(hc_group_id)
    @hc_group_id=hc_group_id
  end

  def hc_required
    if (self.hc_auto_flag=='y' or self.hc_manual_flag=='y')
      return "Yes"
    end
    if (self.hc_auto_flag=='n' and self.hc_manual_flag=='n')
      return "No"
    end
  end

end