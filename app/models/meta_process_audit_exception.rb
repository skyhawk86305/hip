class MetaProcessAuditException < SwareBase
    
  set_table_name("meta_process_audit_exception_v")
  belongs_to :meta_process_audit , :primary_key=>:audit_id,:foreign_key =>:audit_id
  set_primary_key :audit_id

end
