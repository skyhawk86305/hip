class LoadSeveritySample < LoadSample
  
  # Create CSV file using the following DB2 statement:
  # db2 "export to DIM_COMM_SEVERITY.csv of del modified by codepage=1208
  # select
  # 	severity_id,
  # 	severity_cd,
  # 	severity_desc
  # from hip.dim_comm_severity_v"

  def self.load
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      Severity.transaction do
      filename = File.join(RAILS_ROOT, "db", "sample_sware_data","DIM_COMM_SEVERITY.csv")
      CSV.foreach(filename) do |row|
          Severity.create(
          :severity_id     => row[0],
          :severity_cd     => row[1],
          :severity_desc   => nil_if_empty(row[2])
          )
        end
      end
    end
  end
  
end