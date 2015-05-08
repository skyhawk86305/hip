class LoadOsSample < LoadSample

  # Create CSV file using the following DB2 statement:
  # db2 "export to DIM_COMM_OS.csv of del modified by codepage=1208
  # select
  #   os_id,
  # 	os_type,
  # 	os_product,
  # 	vendor_name,
  # 	os_name,
  # 	os_ver
  # from ad.dim_comm_os_v"			

  def self.load
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      Os.transaction do
      filename = File.join(RAILS_ROOT, "db", "sample_sware_data","DIM_COMM_OS.csv")
      CSV.foreach(filename) do |row|
          Os.create(
          :os_id        => row[0],
          :os_type      => row[1],
          :os_product   => row[2],
          :vendor_name  => row[3],
          :os_name      => row[4],
          :os_ver       => row[5]
          )
        end
      end
    end
  end
  
end