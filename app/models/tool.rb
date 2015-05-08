class Tool < SwareBase
    
  set_table_name("dim_comm_tool_v")
  set_primary_keys :tool_id
  has_many :assets, :foreign_key=> :tool_id

  named_scope :tool_list, :select=>"DISTINCT manager_name"
  named_scope :hc_tool_names, :select => 'tool_name', :conditions => {:hc_type => 'y'}, :order => "lower(tool_name) asc"
end
