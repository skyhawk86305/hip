class Vuln < ActiveRecord::Base
  
  set_table_name("dim_comm_vuln_v")
  set_primary_keys :vuln_id

  has_many :fact_scans, :primary_key=>:finding_vid,:foreign_key=>:vuln_id
  has_many :suppression, :primary_key=>:suppress_id,:foreign_key=>:vuln_id

  named_scope :category, :select=>"DISTINCT sarm_cat_name",:conditions=>"sarm_cat_name is not null"
end
