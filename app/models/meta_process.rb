class MetaProcess < SwareBase
    
  set_table_name("meta_process_v")
  
  has_many :meta_process_audits, :primary_key=>:process_id,:foreign_key =>:process_id
  
  set_primary_key :process_id

  named_scope :generic_transform, :conditions=> {:process_name => "generic_transform",
  	:function => "transform", :function_step => 1, :feed => "mhc"}
  named_scope :scan_post_tranform_per_server, :conditions=> {:process_name => "scan_post_transform",
  	:function => "transform", :function_step => 2, :feed => "scan"}
  named_scope :scan_post_tranform_main, :conditions=> {:process_name => "scan_post_transform",
  	:function => "transform", :function_step => 1, :feed => "scan"}

end
