class Org < SwareBase
 
  set_table_name("dim_comm_org_v")
  set_primary_keys :org_l1_id,:org_id
  has_many :roles_groups, :foreign_key => [:org_l1_id, :org_id]
  has_many :assets, :foreign_key => [:org_l1_id, :org_id]
  has_many :asset_scans, :foreign_key => [:org_l1_id, :org_id]
  has_many :hc_groups, :foreign_key => [:org_l1_id, :org_id]
  has_many :ooc_groups, :foreign_key => [:org_l1_id, :org_id]
  has_many :fact_scans,:primary_key=>[:org_l1_id,:org_id],:foreign_key=>[:org_l1_id,:org_id]
  has_many :suppressions ,:primary_key=>[:org_l1_id,:org_id],:foreign_key=>[:org_l1_id,:org_id]
  # offical list of orgs for application.  Note that org_li_id is IGA which has suborgs -- so this will show the IGA suborgs but not the IGA l1 org
  named_scope :service_hip, :conditions=>["org_service_hip = ? and (org_l1_id=org_id or (org_l1_id = 8281 and org_id != org_l1_id))","y"], :order=>:org_name

  accepts_nested_attributes_for :roles_groups,:allow_destroy=>true

  def unassigned_systems
    id = self.id
    sql="select count(*) as count from dim_comm_tool_asset_hist_v as ah
    left join hip_asset_group_v as ag on ag.asset_id = ah.tool_asset_id
    where (select asset_freeze_timestamp from hip_period_v
    where month_of_year=month(current_timestamp) and
    year=year(current_timestamp) and org_l1_id=0 and org_id=0)
    between ah.row_from_timestamp and coalesce(ah.row_to_timestamp,current_timestamp)
    and (ah.org_l1_id=#{id[0]} and ah.org_id=#{id[1]}) and ag.hc_group_id is null"
    Org.count_by_sql(sql)
  end
end