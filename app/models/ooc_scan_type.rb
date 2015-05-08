class OocScanType < SwareBase
  
  set_table_name "hip_ooc_scan_type_v"
  
  set_primary_keys :ooc_scan_type
  has_many :ooc_group_types
  validates_presence_of :ooc_group_type
  validates_format_of :ooc_scan_publish, :with => /^y|n$/, :message => "is missing or invalid"
  
  before_save :set_lu_data
  before_save :set_defaults

  ########
  private
  ########

  def set_defaults
  	active_in_gui = 'y' if active_in_gui.nil?
  end
  
end
