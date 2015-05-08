class LoadToolSample < LoadSample
  
  # Create CSV file using the following DB2 statement:
  # db2 "export to DIM_COMM_TOOL.csv of del modified by codepage=1208
  # select
  # 	tool_id,
  # 	tool_name,
  # 	manager_name,
  #   hc_type,
  #   vuln_type,
  #   patch_type,
  #   ids_type,
  #   fw_type,
  #   asset_type
  # from hip.dim_comm_tool_v"

  def self.load
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      Tool.transaction do
      filename = File.join(RAILS_ROOT, "db", "sample_sware_data","DIM_COMM_TOOL.csv")
      CSV.foreach(filename) do |row|
          Tool.create(
          :tool_id       => row[0],
          :tool_name     => row[1],
          :manager_name  => row[2],
          :hc_type       => row[3],
          :vuln_type     => row[4],
          :patch_type    => row[5],
          :ids_type      => row[6],
          :fw_type       => row[7],
          :asset_type    => row[8]
          )
        end
      end
    end
  end
  
end