class Role < SwareBase
  
  set_table_name "hip_role_v"

  validates_presence_of :has_associated_org, :if =>:has_category
  validates_presence_of :has_associated_geo, :unless =>[:has_org,:has_category]
  validates_presence_of :role_name
  set_primary_keys :role_name
  has_many :rolesgroups
  
  before_create :set_created_at
  before_save :set_lu_data

  def has_category
    /y/i === self.has_associated_category
  end

  def has_geo
    /y/i === self.has_associated_geo
  end

  def has_org
    # TODO: check if this should be *org*
    /y/i === self.has_associated_geo
  end
  
end
