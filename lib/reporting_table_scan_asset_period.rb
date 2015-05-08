class ReportingTableScanAssetPeriod
  
  TABLE_NAME = 'dim_scan_asset_period_v'

  def self.load

    insert = "insert into #{TABLE_NAME} (
    PERIOD_MONTH_ID,
    ASSET_VID,
    ORG_L1_ID,
    ORG_ID,
    ASSET_ID,
    IP_STRING_PRIMARY,
    IP_INT_PRIMARY,
    IP_STRING_LIST,
    HOST_NAME,
    OS_ID,
    OS_TYPE,
    OS_PRODUCT,
    OS_VENDOR_NAME,
    OS_NAME,
    OS_VER,
    SYSTEM_STATUS,
    ENCRYPTION_FLAG,
    HC_AUTO_FLAG,
    HC_INTERVAL_WEEKS,
    HC_MANUAL_FLAG,
    HC_MANUAL_INTERVAL_WEEKS,
    SECURITY_POLICY_NAME,
    DISASTER_RECOVERY_FLAG,
    INTERNET_ACCESSIBLE_FLAG,
    VITAL_BUSINESS_PROCESS_FLAG,
    HC_START_DATE,
    HC_GROUP_ID,
    HC_GROUP_NAME,
    HC_CREATION_TIMESTAMP,
    LU_TIMESTAMP
    ) (select 
    op.PERIOD_MONTH_ID,
    assh.tool_ASSET_VID,
    op.ORG_L1_ID,
    op.ORG_ID,
    assh.tool_ASSET_ID,
    assh.IP_STRING_PRIMARY,
    assh.IP_INT_PRIMARY,
    assh.IP_STRING_LIST,
    assh.HOST_NAME,
    assh.OS_ID,
    os.OS_TYPE,
    os.OS_PRODUCT,
    os.VENDOR_NAME,
    os.OS_NAME,
    os.OS_VER,
    assh.SYSTEM_STATUS,
    assh.ENCRYPTION_FLAG,
    assh.HC_AUTO_FLAG,
    assh.HC_auto_INTERVAL_WEEKS,
    assh.HC_MANUAL_FLAG,
    assh.HC_MANUAL_INTERVAL_WEEKS,
    assh.SECURITY_POLICY_NAME,
    assh.DISASTER_RECOVERY_FLAG,
    assh.INTERNET_ACCESSIBLE_FLAG,
    assh.VITAL_BUSINESS_PROCESS_FLAG,
    assh.HC_START_DATE,
    hcg.HC_GROUP_ID,
    hcg.GROUP_NAME,
    hcg.CREATed_at,
    current_timestamp
    from dim_scan_org_period_v as op
    join dim_comm_tool_asset_hist_v as assh on assh.org_l1_id = op.org_l1_id and assh.org_id = op.org_id and op.asset_freeze_timestamp between assh.row_from_timestamp and coalesce(assh.row_to_timestamp, current_timestamp)
    join dim_comm_os_v as os on os.os_id = assh.os_id
    join hip_asset_group_v as assg on assg.asset_id = assh.tool_asset_id
    join hip_hc_group_v as hcg on hcg.hc_group_id = assg.hc_group_id
    where hcg.is_current = 'y'
    )"
    SwareBase.transaction do
      clear
      SwareBase.connection.execute(insert)
    end
  end
  
  def self.clear
    delete = "delete from #{TABLE_NAME}"
    SwareBase.transaction do
      SwareBase.connection.execute(delete)
    end
  end

end