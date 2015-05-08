class ReportingTables
  
  def self.update
    ReportingTableFactsScanPeriod.clear
    ReportingTableScanScanPeriod.clear
    ReportingTableScanAssetPeriod.clear
    ReportingTableScanSuppressPeriod.clear
    ReportingTableScanOrgPeriod.clear
    
    ReportingTableScanOrgPeriod.load
    ReportingTableScanSuppressPeriod.load
    ReportingTableScanAssetPeriod.load
    ReportingTableScanScanPeriod.load
    ReportingTableFactsScanPeriod.load
  end
  
end