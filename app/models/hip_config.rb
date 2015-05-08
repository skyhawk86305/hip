class HipConfig < SwareBase

  before_save :set_lu_data
  
  set_table_name("hip_config_v")
  set_primary_key :config_id

  validates_length_of :key, :maximum=>25
  validates_length_of :value, :maximum=>255
  validates_presence_of :key,:value

end