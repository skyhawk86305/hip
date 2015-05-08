class MissedScanReason < SwareBase
  
  set_table_name("hip_missed_scan_reason_v")
  set_primary_key :missed_scan_reason_id
  
  before_save :set_lu_data
  
  has_many :MissedScan
  
end
