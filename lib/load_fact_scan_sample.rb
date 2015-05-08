class LoadFactScanSample < LoadSample

  # Create CSV file using the following DB2 statement:
  # export to FACT_SCAN.csv of del modified by codepage=1208
  # select
  # 	FINDING_VID,
  # 	FINDING_ID, 
  # 	varchar_format(ROW_FROM_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'),
  # 	ROW_FROM_DATE_ID, 
  # 	varchar_format(ROW_TO_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'),
  # 	ROW_TO_DATE_ID, 
  # 	ROW_TO_DATE_ID_GEN, 
  # 	varchar_format(SCAN_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'),
  # 	ASSET_ID, 
  # 	ORG_ID, 
  # 	ORG_L1_ID, 
  # 	ORG_L1_ID_GEN, 
  # 	SCAN_SERVICE, 
  # 	SCAN_TOOL_ID, 
  # 	VULN_ID, 
  # 	SEVERITY_ID, 
  # 	PORT, 
  # 	PROTOCOL_ID, 
  # 	varchar_format(LU_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'),
  # 	QUALITY_ID, 
  # 	FINDING_HASH, 
  # 	FINDING_TEXT
  # from hip.fact_scan_v
  # where org_l1_id in (3568, 3575, 8281);
  #
  # org_l1_id == org_id == 3568 is Case New Holland
  # org_l1_id == org_id == 3575 is Belk Inc
  # org_l1_id == 8281 is the IBM Global Account.  The org_id's are the individual areas of IGA.  We don't have sample data
  # for all the IGA orgs, just for the following:
  #   8281	IBM Global Account (IGA) - United States
  #   8282	Americas-US-UISL-ALM-Unix
  #   8284	Americas-US-UISL-NUS_W_DRBLDUNIX
  #   8289	Americas-US-UISL-RCHLotus-AIX
  #   8294	Americas-US-UISL-SAIL-Unix
  #   8296	Americas-US-UISL-Apex-Unix
  #   8298	Americas-US-UISL-AUSInfra-AIX
  #   8299	Americas-US-UISL-BLD-INET
  #   8312	Americas-US-UISL-Pegasus-AIX
  #   8314	Americas-US-UISL-SSMULTLIN-Linux
  #   8315	Americas-US-UISL-USUNIX
  #   8345	Americas-US-UISL-BTV-SS
  #   8346	Americas-US-UISL-SBY-Unix
  #   8347	Americas-US-UISL-SAP-AIX
  #   8348	Americas-US-UISL-GSA-Unix
  #   8349	Americas-US-UISL-IBM DR-Unix
  #   8350	Americas-US-UISL-300MM-Linux
  #   8352	Americas-US-SSO-AHEPOK-AIXSS
  #   8353	Americas-US-UISL-Watson-AIX Server
  #   8354	Americas-US-UISL-300MM-AIX
  #   8365	Americas-US-UISL-CRM Prod-AIX
  #   8366	Americas-US-UISL-END-AIX
  #   8367	Americas-US-UISL-IBMBLD OOP-UNIX
  #   8372	Americas-US-UISL-MDFSH-Unix
  #   8374	Americas-US-UISL-POKInfraNetwork-Unix
  #   8376	Americas-US-UISL-SCOtivoli-Unix
  #   8377	Americas-US-UISL-Watson-Linux Server
  #   8383	Americas_US_MVS
  #   8401	Americas-US-UISL-BTVInfra-Unix
  #   8405	Americas-US-UISL-P2P-AIX
  #   8431	Americas-US-CrossOrg-ODCS-UNIX-AHE-SS
  
  # This is a special class to load the fact_scan_v table in development.  The applicaion will not
  # update this table except for one specific column, so this special class is needed to load
  # development data
  class FactScanLoad < SwareBase

    set_table_name("fact_scan_v")
    set_primary_keys :finding_vid

    before_save :set_lu_data
    
    attr_readonly :row_to_date_id_gen
    attr_readonly :org_l1_id_gen

    def bulk_insert_start_sql
      unless self.id
        raise CompositeKeyError, "Composite keys do not generated ids from sequences, you must provide id values"
      end
      attributes_minus_pks = attributes_with_quotes(false, false)
      quoted_pk_columns = self.class.primary_key.map { |col| connection.quote_column_name(col) }
      cols = quoted_column_names(attributes_minus_pks) << quoted_pk_columns
      "INSERT INTO #{self.class.quoted_table_name} (#{cols.join(', ')}) VALUES "
    end

    def bulk_insert_values_sql
      unless self.id
        raise CompositeKeyError, "Composite keys do not generated ids from sequences, you must provide id values"
      end
      attributes_minus_pks = attributes_with_quotes(false, false)
      vals = attributes_minus_pks.values << quoted_id
      "(#{vals.join(', ')})"
    end

    private
    def create_without_callbacks
      unless self.id
        raise CompositeKeyError, "Composite keys do not generated ids from sequences, you must provide id values"
      end
      attributes_minus_pks = attributes_with_quotes(false, false)
      quoted_pk_columns = self.class.primary_key.map { |col| connection.quote_column_name(col) }
      cols = quoted_column_names(attributes_minus_pks) << quoted_pk_columns
      vals = attributes_minus_pks.values << quoted_id
      connection.insert(
        "INSERT INTO #{self.class.quoted_table_name} " +
          "(#{cols.join(', ')}) " +
          "VALUES (#{vals.join(', ')})",
        "#{self.class.name} Create",
        self.class.primary_key,
        self.id
      )
      @new_record = false
      return true
    end
  end
  
  def self.load
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      chunk_size = 500
      row = []
      start_sql = ""
      values_sql_array = []
      file = File.open(File.join(RAILS_ROOT, "db", "sample_sware_data","FACT_SCAN.csv"), 'rb')
      table = CSV.new(file, :headers => false)
      until row.nil?
        chunk_size.times do
          break unless row = table.shift

          fsl = FactScanLoad.new(
            :finding_vid        => row[0],
            :finding_id         => row[1],
            :row_from_timestamp => roll_date_forward(row[2]),
            :row_from_date_id   => row[3],
            :row_to_timestamp   => roll_date_forward(nil_if_empty(row[4])),
            :row_to_date_id     => nil_if_empty(row[5]),
            :row_to_date_id_gen => nil_if_empty(row[6]),
            :scan_timestamp     => roll_date_forward(row[7]),
            :asset_id           => row[8],
            :org_id             => row[9],
            :org_l1_id          => row[10],
            #:org_l1_id_gen      => row[11], 
            :scan_service       => row[12],
            :scan_tool_id       => translate_tool_id(row[13]),
            :vuln_id            => row[14].to_s.to_i == 788 ? 0 : row[14],    # Workaround for our current data that has 788 for unknown
            #:vuln_id            => 788,       # <-- work around until dim_comm_vuln is updated with health check vulns
            :severity_id        => random_sev_id(),    #row[15],  <-- provide a variety of severities since this data doesn't have prod values
            :port               => row[16],
            :protocol_id        => row[17],
            :lu_timestamp       => roll_date_forward(row[18]),
            :quality_id         => row[19],
            :finding_hash       => row[20],
            :finding_text       => row[21]
          )
          start_sql = fsl.bulk_insert_start_sql
          values_sql_array << fsl.bulk_insert_values_sql
        end

        if values_sql_array.size > 0
          FactScanLoad.connection.execute(start_sql + values_sql_array.join(', '))
          start_sql = ""
          values_sql_array = []
        end
      end
    end
  end
  
  def self.random_sev_id()
    [1,2,3,5][rand(4)]
  end

end
