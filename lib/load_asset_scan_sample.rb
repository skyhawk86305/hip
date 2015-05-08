class LoadAssetScanSample < LoadSample

  # Create CSV file using the following DB2 statement:
  # export to DIM_COMM_TOOL_ASSET_SCAN_HIST.csv of del modified by codepage=1208
  # select
  # 	ORG_L1_ID,
  # 	ORG_ID,
  # 	ASSET_ID,
  # 	TOOL_ID,
  # 	SCAN_DATE_ID,
  # 	varchar_format(SCAN_START_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'),
  # 	varchar_format(SCAN_STOP_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'),
  # 	SCAN_SERVICE,
  # 	SCAN_ID,
  # 	SOURCE_SCAN_ID,
  # 	HOST_STATUS,
  # 	SCANNER_HOST_NAME,
  # 	SCAN_PARMS,
  # 	EXTRACT_BATCH_ID,
  # 	TRANSFORM_BATCH_ID,
  # 	LOAD_BATCH_ID,
  # 	varchar_format(LU_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF')
  # from hip.dim_comm_tool_asset_scan_hist_v
  # where org_l1_id in (3568, 3575, 8281);

  def self.load
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      AssetScan.transaction do
       filename = File.join(RAILS_ROOT, "db", "sample_sware_data","DIM_COMM_TOOL_ASSET_SCAN_HIST.csv")
       CSV.foreach(filename) do |row|
          AssetScan.create(
            :org_l1_id            => row[0],
            :org_id               => row[1],
            :asset_id             => row[2],
            :tool_id              => translate_tool_id(row[3]),
            :scan_date_id         => row[4],
            :scan_start_timestamp => roll_date_forward(row[5]),
            :scan_stop_timestamp  => roll_date_forward(row[6]),
            :scan_service         => row[7],
            :scan_id              => row[8],
            :source_scan_id       => row[9],
            :host_status          => row[10],
            :scanner_host_name    => row[11],
            :scan_parms           => row[12],
            :extract_batch_id     => row[13],
            :transform_batch_id   => row[14],
            :load_batch_id        => row[15],
            :lu_timestamp         => roll_date_forward(row[16])
          )
        end
      end
    end
  end

end