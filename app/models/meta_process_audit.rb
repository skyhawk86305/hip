class MetaProcessAudit < SwareBase
    
  set_table_name("meta_process_audit_v")
  
  has_many :meta_process_audit_exceptions, :primary_key=>:audit_id,:foreign_key =>:audit_id
  
  set_primary_key :audit_id

end
