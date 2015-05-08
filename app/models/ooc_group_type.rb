class OocGroupType < SwareBase
  
  set_table_name "hip_ooc_group_type_v"

  set_primary_keys :ooc_group_type
  
  before_save :set_lu_data

end
