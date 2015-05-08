class Os < SwareBase
    
  set_table_name("dim_comm_os_v")
  set_primary_keys :os_id

  named_scope :os_product_list, :select=>"DISTINCT os_product", :order=>"os_product ASC"
end
