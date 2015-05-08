class LoadAssetSample < LoadSample

  # Create CSV file using the following DB2 statement:
  # db2 "export to DIM_COMM_TOOL_ASSET_HIST.csv of del modified by codepage=1208 select 
  # TOOL_ASSET_VID, 
  # TOOL_ASSET_ID, 
  # varchar_format(ROW_FROM_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'), 
  # varchar_format(ROW_TO_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'), 
  # ORG_L1_ID, 
  # MANAGER_ID, 
  # SOURCE_ASSET_ID, 
  # SOURCE_ORG_ID, 
  # IP_STRING_PRIMARY, 
  # IP_INT_PRIMARY, 
  # IP_STRING_LIST, 
  # HOST_NAME, 
  # TOOL_ID, 
  # ORG_ID, 
  # OS_ID, 
  # OS_SOURCE_TEXT, 
  # SYSTEM_STATUS, 
  # ENCRYPTION_FLAG, 
  # varchar_format(LU_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'), 
  # LU_USERID 
  # from hip.dim_comm_tool_asset_hist_v"	
  #w where org_l1_id in (3568, 3575, 8281);			

  def self.load
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      Asset.transaction do
        filename = File.join(RAILS_ROOT, "db", "sample_sware_data","DIM_COMM_TOOL_ASSET_HIST.csv")
        CSV.foreach(filename) do |row|
          org_l1_id = row[4].to_s.to_i
          org_id = row[13].to_s.to_i
          Asset.create(
          :tool_asset_vid       => row[0],
          :tool_asset_id        => row[1],
          :row_from_timestamp   => org_l1_id == BELK || org_l1_id == IGA ? row[2] : roll_date_forward(row[2]),
          :row_to_timestamp     => org_l1_id == BELK || org_l1_id == IGA ? row[3] : roll_date_forward(nil_if_empty(row[3])),
          :org_l1_id            => row[4],
          :manager_id           => translate_tool_id(row[5]),
          :source_asset_id      => row[6],
          :source_org_id        => nil_if_empty(row[7]),
          :ip_string_primary    => nil_if_empty(row[8]),
          :ip_int_primary       => nil_if_empty(row[9]),
          :ip_string_list       => nil_if_empty(row[10]),
          :host_name            => nil_if_empty(row[11]),
          :tool_id              => translate_tool_id(row[12]),
          :org_id               => nil_if_empty(row[13]),
          :os_id                => nil_if_empty(row[14]),
          :os_source_text       => nil_if_empty(row[15]),
          :system_status        => row[16],
          :encryption_flag      => row[17],
          :lu_timestamp         => roll_date_forward(nil_if_empty(row[18])),
          :lu_userid            => nil_if_empty(row[19]),
          :hc_auto_flag         => 'n',
          :internet_accessible_flag => 'n',
          :vital_business_process_flag => 'n'
          )
        end
      end
    end
  end

end