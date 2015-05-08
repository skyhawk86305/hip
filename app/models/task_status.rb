class TaskStatus < SwareBase
  attr_accessor :per_page,:end_scheduled_timestamp ,:start_scheduled_timestamp 
  set_table_name("hip_task_status_v")
  set_primary_key :task_id

  before_save :set_lu_data
    
end
