class SuppressGroup < SwareBase

  set_table_name("hip_suppress_group_v")
  set_primary_keys [:suppress_id,:hc_group_id]

  has_many :hc_groups 
  has_many :suppressions

  before_save :set_lu_data
end
