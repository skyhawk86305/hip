class LoadOrgSample < LoadSample

  # Create CSV file using the following DB2 statement:
  # db2 "export to DIM_COMM_ORG.csv of del modified by codepage=1208
  # select
  # 	ORG_L1_ID						,
  # 	ORG_ID							,
  # 	ORG_NAME						,
  # 	ORG_TYPE						,
  # 	ORG_LEVEL						,
  # 	ORG_VREG_ID					,
  # 	ORG_ECM_ACCOUNT_ID	,
  # 	ORG_ECM_ACCOUNT_NAME,
  # 	ORG_ECM_ACCOUNT_TYPE,
  # 	ORG_PRIMARY_OWNER_ID,
  # 	ORG_BACKUP_OWNER_ID	,
  # 	ORG_PARENT_ID				,
  # 	ORG_L1_NAME					,
  # 	ORG_L1_NAME_TINY		,
  # 	ORG_L1_NAME_SHORT		,
  # 	ORG_L1_NAME_VREG		,
  # 	ORG_L1_TYPE					,
  # 	ORG_L1_VREG_ID			,
  # 	ORG_L1_RTID_ID			,
  # 	ORG_L2_ID						,
  # 	ORG_L2_NAME					,
  # 	ORG_L2_TYPE					,
  # 	ORG_L2_VREG_ID			,
  # 	ORG_L3_ID						,
  # 	ORG_L3_NAME					,
  # 	ORG_L3_TYPE					,
  # 	ORG_L4_ID						,
  # 	ORG_L4_NAME					,
  # 	ORG_L4_TYPE					,
  # 	ORG_L5_ID						,
  # 	ORG_L5_NAME					,
  # 	ORG_L5_TYPE					,
  # 	ORG_STATUS					,
  # 	ORG_INDUSTRY_ID			,
  # 	ORG_INDUSTRY_NAME		,
  # 	ORG_COUNTRY_ID			,
  # 	ORG_COUNTRY_NAME		,
  # 	ORG_ECM_INSTANCE		,
  # 	ORG_SERVICE_ECM			,
  # 	ORG_SERVICE_VULN		,
  # 	ORG_SERVICE_HEALTH	,
  # 	varchar_format(LU_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF'),
  # 	LU_OPERATION,
  #   ORG_SERVICE_HIP
  #  from hip.dim_comm_org_v"			
  
  def self.load
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      Org.transaction do
          filename = File.join(RAILS_ROOT, "db", "sample_sware_data","DIM_COMM_ORG.csv")
          CSV.foreach(filename, col_sep: ",", encoding: "UTF-8") do |row|
          org_l1_id = row[0].to_s.to_i
          org_id = row[1].to_s.to_i
          Org.create(
          :org_l1_id            => org_l1_id,
          :org_id						    => org_id,
          :org_name					    => row[2],
          :org_type					    => row[3],
          :org_level					  => row[4],
          :org_vreg_id				  => nil_if_empty(row[5]),
          :org_ecm_account_id   => nil_if_empty(row[6]),
          :org_ecm_account_name => nil_if_empty(row[7]),
          :org_ecm_account_type => nil_if_empty(row[8]),
          :org_primary_owner_id => nil_if_empty(row[9]),
          :org_backup_owner_id  => nil_if_empty(row[10]),
          :org_parent_id			  => nil_if_empty(row[11]),
          :org_l1_name				  => row[12],
          :org_l1_name_tiny	    => nil_if_empty(row[13]),
          :org_l1_name_short	  => nil_if_empty(row[14]),
          :org_l1_name_vreg	    => nil_if_empty(row[15]),
          :org_l1_type				  => row[16],
          :org_l1_vreg_id		    => nil_if_empty(row[17]),
          :org_l1_rtid_id		    => nil_if_empty(row[18]),
          :org_l2_id					  => nil_if_empty(row[19]),
          :org_l2_name				  => nil_if_empty(row[20]),
          :org_l2_type				  => nil_if_empty(row[21]),
          :org_l2_vreg_id		    => nil_if_empty(row[22]),
          :org_l3_id					  => nil_if_empty(row[23]),
          :org_l3_name				  => nil_if_empty(row[24]),
          :org_l3_type				  => nil_if_empty(row[25]),
          :org_l4_id					  => nil_if_empty(row[26]),
          :org_l4_name				  => nil_if_empty(row[27]),
          :org_l4_type				  => nil_if_empty(row[28]),
          :org_l5_id					  => nil_if_empty(row[29]),
          :org_l5_name				  => nil_if_empty(row[30]),
          :org_l5_type				  => nil_if_empty(row[31]),
          :org_status				    => nil_if_empty(row[32]),
          :org_industry_id		  => nil_if_empty(row[33]),
          :org_industry_name	  => nil_if_empty(row[34]),
          :org_country_id		    => nil_if_empty(row[35]),
          :org_country_name	    => nil_if_empty(row[36]),
          :org_ecm_instance	    => nil_if_empty(row[37]),
          :org_service_ecm		  => nil_if_empty(row[38]),
          :org_service_vuln	    => nil_if_empty(row[39]),
          :org_service_health   => nil_if_empty(row[40]),
          :lu_timestamp			    => nil_if_empty(row[41]),
          :lu_operation			    => nil_if_empty(row[42]),
          :org_service_hip => org_l1_id == CNH || org_l1_id == BELK || (org_l1_id == IGA && IGA_ORGS_WITH_DATA.include?(org_id)) ? 'y' : nil
          )
        end
      end
    end
  end

end