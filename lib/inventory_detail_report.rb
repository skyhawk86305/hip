class InventoryDetailReport < ScheduledTask

  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config

    # Runs on the 2nd weekday from the last day of the month at 8pm eastern
    schedule_time_utc = ScheduledTask.last_schedule_weekday_monthly(-2,22,0,'Eastern Time (US & Canada)')
    
    tasks = []

    orgs = Org.service_hip
    orgs.each do |org|
      tasks << self.new("Inventory-#{org.org_name[0...20]}",schedule_time_utc, 'y',nil, org)
    end
    return tasks
  end

  attr_reader :name, :last_run_timestamp, :auto_retry, :queued_task_id, :org
  
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id,org)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
    @org = org
  end

  def run
    override_date = @@config[:override_date]
    SwareBase.set_period(override_date) if override_date
    
    #orgs = Org.service_hip
    @period = SwareBase.current_period
    #orgs.each do |org|
    # create dirs
    @org_name = @org.org_name.gsub(/\W/,"_")# replace space with underscore
    @storage_path = "#{RAILS_ROOT}/reports/#{@org_name}/#{@period.asset_freeze_timestamp.strftime("%Y-%m")}"
    FileUtils.makedirs(@storage_path)
    # get asset query
    assets = AssetSearch.inventory_detail_report(org.id.to_s)
    #put system scan status in hash to use later
    @system_scan_status=get_system_scan_status(org)
    #generate the PDF report
    pdf_report(assets, @org)

    #generate the csv for each hc_group
    csv_report(assets, @org)
    #end
    SwareBase.reset_period if override_date
    {:success => true}
  end


  def csv_report(assets,org)
    filename="#{@storage_path}/#{@org_name}_#{Date.new(@period.year,@period.month_of_year,-1).strftime("%m-%d-%Y")}_Inventory_Detail_Report.csv"
    CSV.open(filename, 'wb') do |csv|

      csv << ["TITLE: Cycle End Inventory Detail Report"]
      csv << ["Account: #{org.org_name}"]
      csv << ["Customer ID: #{org.org_ecm_account_id}"]
      csv << ["Locked Inventory Report for Health Check Cycle Month: #{Date.new(@period.year,@period.month_of_year).strftime("%B %Y")}"]
      csv << ["All Data Based on Inventory Locked as of: #{@period.asset_freeze_timestamp.strftime("%m/%d/%Y %H%M")} UTC"]
      csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << [nil] # create new line
      # create headers
      csv << [
        "System Name",
        "IP Address",
        "Operating System",
        "System Status",
        "HC Auto Flag? (Y/N)",
        "HC Auto Interval",
        "HC Man Flag? (Y/N)",
        "HC Man Interval",
        "HC Required? (Y/N)",
        "HC Frequency Interval (wks)",
        "HC Cycle Group",
        "Current HC Cycle (Y,N)",
        "System Scan Status",
        "Missing Reason"
      ]
      assets.each do |asset|
        
        csv << [
          asset.host_name,
          asset.ip_string_list,
          asset.os_product,
          asset.system_status,
          asset.hc_auto_flag,
          asset.hc_auto_interval_weeks.to_s,
          asset.hc_manual_flag,
          asset.hc_manual_interval_weeks.to_s,
          asset.hc_required,
          asset.hc_auto_interval_weeks.to_s,
          asset.group_name.nil? ? 'unassigned': asset.group_name ,
          asset.is_current ,
          @system_scan_status[asset.host_name],
          asset.missed_scan_reason
        ]
      end
    end
  end

  def pdf_report(assets,org)
    
    # period = HipPeriod.current_@period.first
    #assets = AssetSearch.inventory_detail_report(org.id.to_s)
    
    file_prefix="#{@storage_path}/#{@org_name}_#{Date.new(@period.year,@period.month_of_year,-1).strftime("%m-%d-%Y")}_Inventory_Detail_Report"
    
    file_html = File.new("#{file_prefix}.html", "w+")
    file_html.puts "<html>"
    file_html.puts "<head>"
    file_html.puts "<title>Cycle End Inventory Detail Report</title>"
    file_html.puts "<style>"
    file_html.puts ".nobreak { page-break-inside: avoid;}"
    file_html.puts ".center { text-align:center;}"
    file_html.puts "th { background:#000;color:#fff}"
    file_html.puts "/* couldn't get the rotation to work as expected.  cell spacing is off.  revisting later."
    file_html.puts ".rotate-90 { -webkit-transform: rotate(-90deg); white-space:nowrap; overflow: hidden; }*/"
    file_html.puts "</style>"
    file_html.puts "</head>"
    file_html.puts "<body>"
    file_html.puts "<p class='center'>"
    file_html.puts "<b>Cycle End Inventory Detail Report</b><br/>"
    file_html.puts "<b>Account:</b> #{org.org_name}<br/>"
    file_html.puts "<b>Customer ID:</b> #{org.org_ecm_account_id}<br/>"
    file_html.puts "<b>Locked Inventory Report for Health Check Cycle </b> #{Date.new(@period.year,@period.month_of_year).strftime("%B %Y")}<br/>"
    file_html.puts "<b>All Data Based on Inventory Locked as of:</b> #{@period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC<br/>"
    file_html.puts "<b>Report Run Date:</b> #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC<br/>"
    file_html.puts "<b>NOTE: *Data source is Sysreg  **Data derived from sysreg data</b><br/>"
    file_html.puts "</p>"
    file_html.puts "<table style='border: 1px solid black;' rules='all' cellpadding='3px'>"
    assets_to_array(org,assets).each do |cell|
      file_html.puts "<tr>"
      file_html.puts "#{cell[0]}"
      file_html.puts "#{cell[1]}"
      file_html.puts "#{cell[2]}"
      file_html.puts "#{cell[3]}"
      file_html.puts "#{cell[4]}"
      file_html.puts "#{cell[5]}"
      file_html.puts "#{cell[6]}"
      file_html.puts "#{cell[7]}"
      file_html.puts "#{cell[8]}"
      file_html.puts "#{cell[9]}"
      file_html.puts "#{cell[10]}"
      file_html.puts "#{cell[11]}"
      file_html.puts "#{cell[12]}"
      file_html.puts "#{cell[13]}"
      file_html.puts "</tr>"
    end
    file_html.puts "</table>"
    file_html.puts "</body>"
    file_html.puts "</html>"

    file_html.close()
    kit = PDFKit.new(File.new("#{file_prefix}.html"),
      :orientation =>"Portrait" ,
      :header_left => "Account: #{org.org_name}"
    )
    kit.to_file("#{file_prefix}.pdf")
      
  end

  private
  # returns a hash of systems and their system_scan_status
  def get_system_scan_status(org)
    scans = ScanSearch.search({
        "hc_group_id"=>'all',
        "org_id"=>org.id.to_s,
        "scan_tool_id"=>"all",
        "scan_type"=>"",
        "start_date"=>"",
        "end_date"=>"",
        'system_scan_status'=>"all",
        "host_name"=>''
      })
    system_scan_status_by_asset=Hash.new()
    scans.each do |s|
      system_scan_status_by_asset[s.host_name]=s.system_scan_status.nil? ? "":s.system_scan_status
    end
    return system_scan_status_by_asset
  end

  # lookup missing scans reason from asset_id
  # need to lookup period_id, then get the missed_scan_id to then
  # retreive the reason
  def get_missed_scan_reason(asset_id,period_id)
    ms = MissedScan.find(:first,:conditions=>{:asset_id=>asset_id,:period_id=>period_id})
    unless ms.nil?
      msr = MissedScanReason.find(ms.missed_scan_reason_id)
    end
    msr.nil? ? "":msr.missed_scan_reason
  end

  # put the systems and attributes into an array
  # with column names for use with csv and pdf table.
  def assets_to_array(org,assets)
    # column headers for csv and pdf table.
    #system_scan_status=get_system_scan_status(org)
    items=[]
    items.push(
      [
        "<th>*System Name</th>",
        "<th>*IP Address</th>",
        "<th>*Operating System</th>",
        "<th>**System Status</th>",
        "<th class='rotate-90'>*HC Auto Flag? (Y/N)</th>",
        "<th class='rotate-90'>*HC Auto Interval</th>",
        "<th class='rotate-90'>*HC Man Flag? (Y/N)</th>",
        "<th class='rotate-90'>*HC Man Interval</th>",
        "<th class='rotate-90'>**HC Required? (Y/N)</th>",
        "<th class='rotate-90'>*HC Frequency Interval (wks)</th>",
        "<th>HC Cycle Group</th>",
        "<th class='rotate-90'>Current HC Cycle (Y,N)</th>",
        "<th>System Scan Status</th>",
        "<th>Missing Reason</th>"]
    )
    assets.each do |asset|
      items.push([
          "<td valign='top'><div class='nobreak'>#{asset.host_name.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{asset.ip_string_list.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{asset.os_product.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{asset.system_status.to_s}</div></td>",
          "<td valign='top'><div class='nobreak center'>#{asset.hc_auto_flag.to_s}</div></td>",
          "<td valign='top'><div class='nobreak center'>#{asset.hc_auto_interval_weeks.to_s}</div></td>",
          "<td valign='top'><div class='nobreak center'>#{asset.hc_manual_flag.to_s}</div></td>",
          "<td valign='top'><div class='nobreak center'>#{asset.hc_manual_interval_weeks.to_s}</div></td>",
          "<td valign='top'><div class='nobreak center'>#{asset.hc_required.to_s}</div></td>",
          "<td valign='top'><div class='nobreak center'>#{asset.hc_auto_interval_weeks.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{asset.group_name.nil? ? 'unassigned': asset.group_name.to_s }</div></td>",
          "<td valign='top'><div class='nobreak center'>#{asset.is_current.to_s }</div></td>",
          "<td valign='top'><div class='nobreak'>#{@system_scan_status[asset.host_name]}</div></td>",
          "<td valign='top'><div class='nobreak'>#{asset.missed_scan_reason.to_s}</div></td>"
        ]
      )

    end
    return items
  end

end