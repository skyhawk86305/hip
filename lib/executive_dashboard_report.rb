class ExecutiveDashboardReport < ScheduledTask
  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config

    # This is to run once every weekday at midnight eastern
    schedule_time_utc = ScheduledTask.last_schedule_daily(0,0,false,'Eastern Time (US & Canada)')
    return [self.new("Executive Dashboard Report",schedule_time_utc, 'y',nil)]
  end

  attr_reader :name, :last_run_timestamp, :auto_retry ,:queued_task_id
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
  end

  def run
    override_date = @@config[:override_date]
    SwareBase.set_period(override_date) if override_date
    @period = SwareBase.current_period
    @storage_path = "#{RAILS_ROOT}/reports/#{@period.asset_freeze_timestamp.strftime("%Y-%m")}"
    FileUtils.makedirs @storage_path
   
    # create pdf report 
    pdf_report
    # create csv report
    csv_report
    # send message to scheduler
    {:success => true}
  end

  def pdf_report()
    orgs = Org.service_hip

    data =[[
        "<th>Account Name</th>",
        "<th>Total Systems (per sysreg)</th>",
        "<th>Unassigned Systems</th>",
        "<th>Not Current HC Cycle</th>",
        "<th>Current HC Cycle</th>",
        "<th>Missing, no reason given</th>",
        "<th>Available,None Labeled</th>",
        "<th>Labelled,None Released</th>",
        "<th>Total Incomplete (s/b zero)</th>",
        "<th>HC Cycle Scan Released</th>",
        "<th>Missing, reason provided</th>",
        "<th>Total Complete</th>",
        "<th># Suppressed Deviations</th>",
        "<th># Valid Deviations</th>",
        "<th># Suppressed Deviations</th>",
        "<th># Valid Deviations</th>",
        "<th>% Suppressed Deviations</th>",
      ]]
    #total value defaults
    total_assets = 0
    total_unassigned=0
    total_not_current=0
    total_current =0
    total_missing_no_reason=0
    total_available=0
    total_labled=0
    total_incomplete=0
    total_released =0
    total_missing =0
    total_complete=0
    total_unvalidated =0
    total_nr_suppressed=0
    total_nr_valid=0
    total_suppressed=0
    total_valid=0
    total_deviations=0
    total_supp_dev =0
    
    orgs.each do |org|
      assets = AssetSearch.executive_report(org.id.to_s)
      scans = get_scans(org.id.to_s)
      released = get_released_scans(org.id.to_s)
      #not_released =get_not_released_scans(org.id.to_s)
      #total values
      total_assets += assets.size
      total_unassigned += assets.find_all{|a| a.group_name.blank? }.size
      total_not_current+=assets.find_all{|a| a.is_current=="n" }.size
      total_current += assets.find_all{|a| a.is_current=='y'}.size
      total_missing_no_reason += scans.find_all{|s| s.system_scan_status=="Missing, no reason given" }.size
      total_available += scans.find_all{|s|  s.system_scan_status=="Available, none labeled"}.size
      total_labled += scans.find_all{|s| s.system_scan_status=="Labeled, none released"}.size
      total_incomplete += scans.find_all{|s| (s.system_scan_status=="Missing, no reason given" ||
            s.system_scan_status=="Available, none labeled" ||
            s.system_scan_status=="Labeled, none released") }.size
      total_released +=scans.find_all{|s| s.system_scan_status=="Released" }.size
      total_missing += scans.find_all{|s|  s.system_scan_status=="Missing, reason provided"}.size
      total_complete += scans.find_all{|s|  (s.system_scan_status=="Missing, reason provided" ||
            s.system_scan_status=="Released")}.size
      total_nr_suppressed += released.find_all{|r| r.publish_ready_timestamp.nil? }.sum{|a| a.suppressed.to_i}
      total_nr_valid +=released.find_all{|r| r.publish_ready_timestamp.nil? }.sum{|a| a.valid.to_i}
      total_suppressed += released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.suppressed.to_i}
      total_valid+=released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.valid.to_i}
      total_deviations += released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.deviation_count.to_i }
      
      # make sure there are findings that are validated or suppressed
      # accounts with 0 violation findinds will create 0/0 which will fail
      # this test makes sure there is not a divide
      suppression_percent = 0
      unless released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.suppressed.to_i}==0
        suppression_percent = released.find_all{|r| r.publish_ready_timestamp? }.empty? ? 0 : (((released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.suppressed.to_f}).to_f/(total_deviations).to_f * 100)).round
      end  
        
      data << [
        "<td class='nobreak'>#{org.org_name}</td>",
        "<td class='nobreak center'>#{int_with_comma(assets.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(assets.find_all{|a| a.group_name.blank? }.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(assets.find_all{|a| a.is_current=="n" }.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(assets.find_all{|a| a.is_current=='y'}.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(scans.find_all{|s| s.system_scan_status=="Missing, no reason given" }.size).to_s }</td>",
        "<td class='nobreak center'>#{int_with_comma(scans.find_all{|s|  s.system_scan_status=="Available, none labeled"}.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(scans.find_all{|s| s.system_scan_status=="Labeled, none released"}.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(scans.find_all{|s| (s.system_scan_status=="Missing, no reason given" ||
        s.system_scan_status=="Available, none labeled" ||
        s.system_scan_status=="Labeled, none released") }.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(scans.find_all{|s| s.system_scan_status=="Released" }.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(scans.find_all{|s|  s.system_scan_status=="Missing, reason provided"}.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(scans.find_all{|s|  (s.system_scan_status=="Missing, reason provided" ||
        s.system_scan_status=="Released")}.size).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(released.find_all{|r| r.publish_ready_timestamp.nil? }.sum{|a| a.suppressed.to_i}).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(released.find_all{|r| r.publish_ready_timestamp.nil? }.sum{|a| a.valid.to_i}).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.suppressed.to_i}).to_s}</td>",
        "<td class='nobreak center'>#{int_with_comma(released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.valid.to_i}).to_s}</td>",
        "<td class='nobreak center'>#{suppression_percent}%</td>"
      ]
    end

    # put totals in array
    data << [
      "<td>Total - Current Cycle</td>",
      "<td class='nobreak center'>#{int_with_comma(total_assets)}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_unassigned).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_not_current).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_current).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_missing_no_reason).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_available).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_labled).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_incomplete).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_released).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_missing).to_s}</td>",
      "<td class='nobreak  center'>#{int_with_comma(total_complete).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_nr_suppressed).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_nr_valid).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_suppressed).to_s}</td>",
      "<td class='nobreak center'>#{int_with_comma(total_valid).to_s}</td>",
      "<td class='nobreak center'>#{(total_suppressed==0 ) ? "0":((total_suppressed.to_f / total_deviations.to_f )*100).round}%</td>"
    ]

    file_prefix="#{@storage_path}/#{@period.asset_freeze_timestamp.strftime("%Y-%m")}_Executive_Dashboard"
    file_html = File.new("#{file_prefix}.html", "w+")
    file_html.puts "<html>"
    file_html.puts "<head>"
    file_html.puts "<title>Executive Dashboard Report</title>"
    file_html.puts "<style>"
    file_html.puts ".nobreak { page-break-inside: avoid;}"
    file_html.puts ".center { text-align:center;}"
    file_html.puts "</style>"
    file_html.puts "</head>"
    file_html.puts "<body>"
    file_html.puts "<p style='text-align:center'>"
    file_html.puts "<b>Executive Dashboard Report</b><br/>"
    file_html.puts "<b>Health Check Cycle: Month ending:</b> #{Date.new(@period.year,@period.month_of_year,-1).strftime("%m/%d/%Y")}<br/>"
    file_html.puts "<b>In Cycle Inventory Effective date:</b> #{@period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC<br/>"
    file_html.puts "<b>Report Run Date:</b> #{Time.now.utc.strftime("%m/%d/%Y %H:%M")} UTC<br/>"
    file_html.puts "<b>Report # 141P-01</b><br/>"
    file_html.puts "</p>"
    file_html.puts "<table>"
    data.each do |cell|
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
      file_html.puts "#{cell[14]}"
      file_html.puts "#{cell[15]}"
      file_html.puts "#{cell[16]}"
      file_html.puts "#{cell[17]}"
      file_html.puts "#{cell[18]}"
      file_html.puts "</tr>"
    end
    file_html.puts "</table>"
    file_html.puts "</body>"
    file_html.puts "</html>"

    file_html.close()
    kit = PDFKit.new(File.new("#{file_prefix}.html")
    )
    kit.to_file("#{file_prefix}.pdf")
  end

  def csv_report()

    orgs = Org.service_hip
   
    filename="#{@storage_path}/#{@period.asset_freeze_timestamp.strftime("%Y-%m")}_Executive_Dashboard.csv"
    CSV.open(filename, 'wb') do |csv|
    
      csv << ["Executive Dashboard Report for In Cycle Scans"]
      csv << ["Health Check Cycle: Month ending: #{Date.new(@period.year,@period.month_of_year,-1).strftime("%m/%d/%Y")}"]
      csv << ["In Cycle Inventory Effective date: #{@period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << ["Report #141C-01"]
      csv << [nil] # create new line
      # create headers
      csv << [
        "Account Name",
        "Total Systems (per sysreg)",
        "Unassigned Systems",
        "Not Current HC Cycle",
        "Current HC Cycle",
        "Missing, no reason given",
        "Available,None Labeled",
        "Labelled,None Released",
        "Total Incomplete (s/b zero)",
        "HC Cycle Scan Released",
        "Missing, reason provided",
        "Total Complete",
        "# Suppressed Deviations",
        "# Valid Deviations",
        "# Suppressed Deviations",
        "# Valid Deviations",
        "% Suppressed Deviations"
      ]
      total_assets = 0
      total_unassigned=0
      total_not_current=0
      total_current =0
      total_missing_no_reason=0
      total_available=0
      total_labled=0
      total_incomplete=0
      total_released =0
      total_missing =0
      total_complete=0
      total_unvalidated =0
      total_nr_suppressed=0
      total_nr_valid=0
      total_suppressed=0
      total_valid=0
      total_deviations=0
      total_supp_dev =0

      orgs.each do |org|
        assets = AssetSearch.executive_report(org.id.to_s)
        scans = get_scans(org.id.to_s)
        released = get_released_scans(org.id.to_s)
        #not_released =get_not_released_scans(org.id.to_s)

        total_assets += assets.size
        total_unassigned += assets.find_all{|a| a.group_name.blank? }.size
        total_not_current+=assets.find_all{|a| a.is_current=="n" }.size
        total_current += assets.find_all{|a| a.is_current=='y'}.size
        total_missing_no_reason += scans.find_all{|s| s.system_scan_status=="Missing, no reason given" }.size
        total_available += scans.find_all{|s|  s.system_scan_status=="Available, none labeled"}.size
        total_labled += scans.find_all{|s| s.system_scan_status=="Labeled, none released"}.size
        total_incomplete += scans.find_all{|s| (s.system_scan_status=="Missing, no reason given" ||
              s.system_scan_status=="Available, none labeled" ||
              s.system_scan_status=="Labeled, none released") }.size
        total_released +=scans.find_all{|s| s.system_scan_status=="Released" }.size
        total_missing += scans.find_all{|s|  s.system_scan_status=="Missing, reason provided"}.size
        total_complete += scans.find_all{|s|  (s.system_scan_status=="Missing, reason provided" ||
              s.system_scan_status=="Released")}.size
        total_nr_suppressed += released.find_all{|r| r.publish_ready_timestamp.nil? }.sum{|a| a.suppressed.to_i}
        total_nr_valid +=released.find_all{|r| r.publish_ready_timestamp.nil? }.sum{|a| a.valid.to_i}
        total_suppressed += released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.suppressed.to_i}
        total_valid += released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.valid.to_i}
        total_deviations += released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.deviation_count.to_i }
      
        # make sure there are findings that are validated or suppressed
        # accounts with 0 violation findinds will create 0/0 which will fail
        # this test makes sure there is not a divide
        suppression_percent = 0
        unless released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.suppressed.to_i}==0
          suppression_percent = released.find_all{|r| r.publish_ready_timestamp? }.empty? ? 0 : ((( released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.suppressed.to_f}).to_f / (total_deviations).to_f * 100)).round
        end 
      
        csv << [
          org.org_name,
          int_with_comma(assets.size),
          int_with_comma(assets.find_all{|a| a.group_name.blank? }.size),
          int_with_comma(assets.find_all{|a| a.is_current=="n" }.size),
          int_with_comma(assets.find_all{|a| a.is_current=='y'}.size),
          int_with_comma(scans.find_all{|s| s.system_scan_status=="Missing, no reason given" }.size) ,
          int_with_comma(scans.find_all{|s|  s.system_scan_status=="Available, none labeled"}.size),
          int_with_comma(scans.find_all{|s| s.system_scan_status=="Labeled, none released"}.size),
          int_with_comma( scans.find_all{|s| (s.system_scan_status=="Missing, no reason given" ||
                  s.system_scan_status=="Available, none labeled" ||
                  s.system_scan_status=="Labeled, none released") }.size),
          int_with_comma(scans.find_all{|s| s.system_scan_status=="Released" }.size),
          int_with_comma(scans.find_all{|s|  s.system_scan_status=="Missing, reason provided"}.size),
          int_with_comma(scans.find_all{|s|  (s.system_scan_status=="Missing, reason provided" ||
                  s.system_scan_status=="Released")}.size),
          int_with_comma(released.find_all{|r| r.publish_ready_timestamp.nil? }.sum{|a| a.suppressed.to_i}),
          int_with_comma(released.find_all{|r| r.publish_ready_timestamp.nil? }.sum{|a| a.valid.to_i}),
          int_with_comma(released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.suppressed.to_i}),
          int_with_comma(released.find_all{|r| r.publish_ready_timestamp? }.sum{|a| a.valid.to_i}),
          "#{suppression_percent}%"

        ]
      end

      csv << [
        "Total - Current Cycle",
        int_with_comma(total_assets),
        int_with_comma(total_unassigned),
        int_with_comma(total_not_current),
        int_with_comma(total_current),
        int_with_comma(total_missing_no_reason),
        int_with_comma(total_available),
        int_with_comma(total_labled),
        int_with_comma(total_incomplete),
        int_with_comma(total_released),
        int_with_comma(total_missing),
        int_with_comma(total_complete),
        int_with_comma(total_nr_suppressed),
        int_with_comma(total_nr_valid),
        int_with_comma(total_suppressed),
        int_with_comma(total_valid),
        "#{(total_suppressed==0 ) ? "0":((total_suppressed.to_f / total_deviations.to_f )*100).round}%"
      ]
    
    end
   
  end

  def get_scans(org_id)
    ScanSearch.search({
        "hc_group_id"=>"all",
        "org_id"=>org_id,
        "scan_tool_id"=>"all",
        "scan_type"=>"all",
        "start_date"=>"",
        "end_date"=>""
      })
  end

  def get_released_scans(org_id)

    PublishScanSearch.search({
        "hc_group_id"=>"all",
        "org_id"=>org_id,
        "val_status"=>"all",
        "scan_type"=>"all",
        "os"=>"all",
        "publish_status"=>"all"
      })
  end

  def int_with_comma(number, delimiter=",")
    number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
  end
end