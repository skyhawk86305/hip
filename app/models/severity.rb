class Severity < SwareBase

  set_table_name("dim_comm_severity_v")
  set_primary_keys :severity_id

  has_many :severities, :primary_key=>:severity_id, :foreign_key=>:severity_id

end
