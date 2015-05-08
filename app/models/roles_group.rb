class RolesGroup < SwareBase
  attr_accessor :pk_org_id,:org_name

  validates_presence_of :blue_groups_name, :role_name
  validates_presence_of :category, :if => :role_is_deviation_sme
  validates_uniqueness_of :blue_groups_name, :scope => [:role_name, :category, :org_id, :org_l1_id]

  set_table_name "hip_roles_bluegroup_v"

  belongs_to :role, :foreign_key => :role_name
  belongs_to :org, :primary_key=>[:org_l1_id,:org_id], :foreign_key =>[:org_l1_id,:org_id]
  
  before_create :set_created_at
  before_save :set_lu_data

  #validation for category
  def role_is_deviation_sme
    /deviation sme/i === self.role_name
  end

  def pk_org_id
    self.org.id unless self.id.blank?
  end

  def org_name
    org = Org.find(self.pk_org_id) unless id.blank?
    org.org_name if org
  end

  def org_name=(name)
    self.org = Org.find(self.pk_org_id) unless id.blank?
  end

  def self.orphaned 
    org_table_name = Org.table_name
    orphaned_roles_groups = RolesGroup.find(:all,
        :select => 'rg.*',
        :joins => "as rg join #{org_table_name} as o on (o.org_l1_id, o.org_id) = (rg.org_l1_id, rg.org_id) and o.org_service_hip = 'n'")
    return orphaned_roles_groups
  end

  def self.delete_orphaned
    # Eliminate orphaned RolesGroups (RolesGroups that do not have an active HIP customer)
    orphaned_roles_group_ids = orphaned.map {|group| group.id}
    RolesGroup.delete(orphaned_roles_group_ids) unless orphaned_roles_group_ids.empty?
  end

end
