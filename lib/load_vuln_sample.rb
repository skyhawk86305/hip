class LoadVulnSample < LoadSample

  # Create CSV file using the following DB2 statement:
  # db2 "export to DIM_COMM_VULN.csv of del modified by codepage=1208
  # select
  #   VULN_ID,
  #   TITLE,
  #   VULN_RELEASE_DATE,
  #   RISK_TYPE_ID,
  #   RISK_TYPE_NAME,
  #   RISK_TYPE_ORD,
  #   RATING_ID,
  #   RATING_NAME,
  #   REPORTED_VER,
  #   FIXED_VER,
  #   TYPES_ID,
  #   TYPES_NAME,
  #   REF_ID,
  #   REF_NAME,
  #   REF_TITLE,
  #   REF_SUMMARY,
  #   REF_INFO,
  #   REF_VERIFY,
  #   REF_FIX,
  #   REF_NSA_FILE_NAME,
  #   REF_EXPLOIT,
  #   VERIFY_ID,
  #   VERIFY_NAME,
  #   PROTOCOL_TELNET_FLAG,
  #   PROTOCOL_HTTP_FLAG,
  #   PROTOCOL_FTP_FLAG,
  #   PROTOCOL_DNS_FLAG,
  #   PROTOCOL_FINGER_FLAG,
  #   PROTOCOL_SUNRPC_FLAG,
  #   SARM_CAT_NAME,
  #   SARM_CAT_DESC,
  #   OS_NAME_LIST,
  #   OS_VARIANT_NAME_LIST,
  #   OS_DISTRO_NAME_LIST,
  #   OS_DISTRO_VERSION_NAME_LIST
  # from ad.dim_comm_vuln_v"

  def self.load
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      Vuln.transaction do
      filename = File.join(RAILS_ROOT, "db", "sample_sware_data","DIM_COMM_VULN.csv")
      CSV.foreach(filename) do |row|
          Vuln.create(
            :vuln_id                     => row[0],
            :title                       => row[1],
            :vuln_release_date           => row[2],
            :risk_type_id                => row[3],
            :risk_type_name              => row[4],
            :risk_type_ord               => row[5],
            :rating_id                   => row[6],
            :rating_name                 => row[7],
            :reported_ver                => row[8],
            :fixed_ver                   => row[9],
            :types_id                    => row[10],
            :types_name                  => row[11],
            :ref_id                      => row[12],
            :ref_name                    => row[13],
            :ref_title                   => row[14],
            :ref_summary                 => row[15],
            :ref_info                    => row[16],
            :ref_verify                  => row[17],
            :ref_fix                     => row[18],
            :ref_nsa_file_name           => row[19],
            :ref_exploit                 => row[20],
            :verify_id                   => row[21],
            :verify_name                 => row[22],
            :protocol_telnet_flag        => row[23],
            :protocol_http_flag          => row[24],
            :protocol_ftp_flag           => row[25],
            :protocol_dns_flag           => row[26],
            :protocol_finger_flag        => row[27],
            :protocol_sunrpc_flag        => row[28],
            :sarm_cat_name               => row[29],
            :sarm_cat_desc               => row[30],
            :os_name_list                => row[31],
            :os_variant_name_list        => row[32],
            :os_distro_name_list         => row[33],
            :os_distro_version_name_list => row[34]
          )
        end
      end
    end
  end
  
end