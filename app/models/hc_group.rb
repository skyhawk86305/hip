
class HcGroup < SwareBase

  attr_accessor :group_name_search

  set_table_name("hip_hc_group_v")
  set_primary_key :hc_group_id
  # HWB: The following has_many has not been tested and many need to be adjusted.
  has_many :assets, :primary_key => :hc_group_id, :foreign_key => :hc_group_id #, :conditions => {:row_to_timestamp => nil}
  belongs_to :org , :primary_key=>[:org_l1_id,:org_id], :foreign_key=>[:org_l1_id,:org_id]
  belongs_to :suppress_group, :primary_key=>[:suppress_id,:hc_group_id],:foreign_key=>:hc_group_id
  has_many :asset_groups

  before_create :set_created_at
  before_save :set_lu_data, :set_last_current_ts

  named_scope :group_list, :conditions => ["lower(is_current) = 'y'"], :order =>"group_name asc"
  named_scope :current, :conditions => ["lower(is_current) = 'y'"], :order =>"group_name asc"

  validates_presence_of :group_name

  def self.find_all_current_groups
    sql = <<-EOF
    select group.*
    from hip_hc_group_v as group
    join dim_comm_org_v as org on org.org_l1_id = group.org_l1_id and org.org_id = group.org_id
    where org.org_service_hip = 'y'
    and group.is_current = 'y'
    order by org.org_name, group.group_name
    EOF
    return find_by_sql(sql)
  end
  
  def age
    if self.last_current_timestamp
      seconds = Time.now.to_i - self.last_current_timestamp.to_i
      minutes = seconds / 60
      minutes_in_month = 43200.0 # 30 day month
      (minutes.to_f / minutes_in_month).round
    else
      "N/A"
    end
  end

  def set_last_current_ts
    self.last_current_timestamp = Time.now.utc unless self.is_current=='N'
  end

  def self.clear_current
    update_all("is_current = 'n'", "is_current = 'y'")
  end

  end