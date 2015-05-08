class OocExecutiveDashboardReport < ScheduledTask
  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config

    # This is to run once every weekday at midnight eastern
    schedule_time_utc = ScheduledTask.last_schedule_daily(0,0,false,'Eastern Time (US & Canada)')
    return [self.new("OOC Executive Dashboard Report",schedule_time_utc, 'y',nil)]
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
    @time = Time.now || Time.parse(override_date)
    
    @storage_path = "#{RAILS_ROOT}/reports/#{@time.strftime("%Y-%m")}"
    @filename="#{@storage_path}/#{@time.strftime("%Y-%m")}_OOC_Executive_Dashboard"
    FileUtils.makedirs @storage_path
    @title = "Out of Cycle Executive Dashboard Report"
    # create csv report
    csv_report
    # create pdf report 
    pdf_report
   
    # send message to scheduler
    {:success => true}
  end

  # read csv file to create pdf report.
  def pdf_report()
  
    if File.exists?("#{@filename}_241C-01.csv")
      file_html = File.new("#{@filename}.html", "w+")
      file_html.puts "<html>"
      file_html.puts "<head>"
      file_html.puts "<title>#{@title} #241P-01</title>"
      file_html.puts "<style>"
      file_html.puts ".nobreak { page-break-inside: avoid;}"
      file_html.puts ".center { text-align:center;margin-left:auto;margin-right:auto'}"
      file_html.puts "</style>"
      file_html.puts "</head>"
      file_html.puts "<body>"
      file_html.puts "<p style='width:100%;' class='center'>"
      file_html.puts "<b>#{@title}</b><br/>"
      file_html.puts "<b>Report Run Date:</b> #{Time.now.utc.strftime("%m/%d/%Y %H:%M")} UTC<br/>"
      file_html.puts "<b>Report #241P-01</b>"
      file_html.puts "</p>"
      file_html.puts "<table>"
      
      row_num=0
    
      CSV.foreach("#{@filename}_241C-01.csv") do |row|
        #  puts "ROW: #{row.inspect}"
     
        if row_num==4
          file_html.puts "<tr>"
          row.each do |cell|
            file_html.puts  "<th>#{cell}</th>"
          end     
          file_html.puts "</tr>"
        end
        if row_num>4
          file_html.puts "<tr>"
          row.each do |cell|
            file_html.puts  "<td class='nobreak'>#{cell}</td>"
          end
          file_html.puts "</tr>"
        end
      
        row_num+=1
      end

      file_html.puts "</table>"
      file_html.puts "</body>"
      file_html.puts "</html>"

      file_html.close()
      kit = PDFKit.new(File.new("#{@filename}.html")
      )
      kit.to_file("#{@filename}_241P-01.pdf")
    end
  end

  def csv_report()
   
    chip_ids=APP['ooc_executive_report_chip_ids']
   
    unless chip_ids.blank?
      orgs = Org.find(:all,
        :conditions=>"org_ecm_account_id in (#{chip_ids.split(',').map{|c| "'#{c}'"}.join(',')}) 
        and org_service_hip='y' 
        and (org_l1_id=org_id or (org_l1_id = 8281 and org_id != org_l1_id))" ,
        :order=>"org_name")
    else
      orgs = Org.service_hip
    end
   
    #filename="#{@storage_path}/#{@time.strftime("%Y-%m")}_OOC_Executive_Dashboard"
    CSV.open("#{@filename}_241C-01.csv", 'w+') do |csv|
    
      csv << [@title]
      csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << ["Report # 241C-01"]
      csv << [nil] # create new line
      # create headers
      csv << [
        "Account Name",
        "# Systems Transition Status",
        "# Systems Production Status",
        "Total Systems (per sysreg)",
        "OOC Group Type",
        "# Unassigned Systems",
        "# Systems in Inactive Groups",
        "# Systems in Active Group",
        "OOC Scan Type",
        "Unavailable without Reason",
        "Available,None Labeled",
        "Labeled,None Released",
        "Total Incomplete (s/b zero)",
        "Released",
        "Missing with Reason",
        "Total Complete",
        "# Scans Labeled not Released",
       # "# Scans w/0 Unvalidated Deviations (ready to release)",
       # "# Scans w/1+ Unvalidated Deviations (not released)",
       # "# Unvalidated Deviations (not released)",
        "# Suppressed Deviations (not released)",
        "Total Deviations",
        "# Scans Released",
        "# Scans w/0 Valid Deviations (released)",
        "# Scans w/1+ Valid Deviations (released)",
        "# Valid Deviations (released)",
        "# Suppressed Deviations",
        "Total Deviations",
        "Average # Valid Deviations Per Server (released)"
      ]
      orgs.each do |org|
        OocScanType.all.each do |type|
       
          search_params={
            :org_id=>org.to_param, #"#{org.org_l1_id},#{org.org_id}",
            :ooc_scan_type=>type.ooc_scan_type,
            :ooc_group_type=>type.ooc_group_type,
            :exec_dashboard_query=>true
          }

          account_dashboard_results = OocReportDashboardSearch.search(search_params)
          unassigend_assets_count = nil
          current_groups_total = nil
          not_current_groups_total = nil
          current_totals_by_group = {}
          not_current_totals_by_group = {}
          account_dashboard_results.each do |row|
            if row[:ooc_group_name].nil? && row[:is_current].nil?
              unassigend_assets_count = row
            elsif row[:ooc_group_name].blank? && row[:is_current] == 'active'
              current_groups_total = row
            elsif row[:ooc_group_name].nil? && row[:is_current] == 'inactive'
              not_current_groups_total = row
            elsif row[:is_current] == 'active'
              current_totals_by_group[row[:ooc_group_name]] = row
            else
              not_current_totals_by_group[row[:ooc_group_name]] = row
            end
          end

          csv << [
            org.org_name,
            unassigend_assets_count[:trans_count].to_i + current_groups_total[:trans_count].to_i + not_current_groups_total[:trans_count].to_i,
            unassigend_assets_count[:prod_count].to_i + current_groups_total[:prod_count].to_i + not_current_groups_total[:prod_count].to_i,
            unassigend_assets_count[:trans_count].to_i + current_groups_total[:trans_count].to_i +
              unassigend_assets_count[:prod_count].to_i + current_groups_total[:prod_count].to_i ,
            type.ooc_group_type,
            unassigend_assets_count[:trans_count].to_i + unassigend_assets_count[:prod_count].to_i, 
            not_current_groups_total[:trans_count].to_i + not_current_groups_total[:prod_count].to_i,
            current_groups_total[:prod_count].to_i + current_groups_total[:trans_count].to_i,
            type.ooc_scan_type,
            current_groups_total[:miss_no_reason].to_i,
            current_groups_total[:none_labeled].to_i,
            current_groups_total[:none_released].to_i,
            current_groups_total[:incomplete].to_i,
            current_groups_total[:released].to_i,
            current_groups_total[:miss_reason].to_i,
            current_groups_total[:complete].to_i,
            current_groups_total[:none_released].to_i,
            #current_groups_total[:unreleased_no_valid_deviations_scan_count].to_i ,
            #current_groups_total[:unreleased_unvalidated_scans_count].to_i,
            #current_groups_total[:unreleased_unvalidated_deviation_count].to_i ,
            current_groups_total[:unreleased_suppress_deviation_count].to_i ,
            current_groups_total[:unreleased_unvalidated_deviation_count].to_i + current_groups_total[:unreleased_suppress_deviation_count].to_i +
            current_groups_total[:unreleased_valid_deviation_count].to_i,
            current_groups_total[:released_scan_count],
            current_groups_total[:released_no_valid_deviations_scan_count].to_i,
            current_groups_total[:released_scan_valid_count].to_i ,
            current_groups_total[:released_valid_deviation_count].to_i ,
            current_groups_total[:released_suppress_deviation_count].to_i,
            current_groups_total[:released_valid_deviation_count].to_i+current_groups_total[:released_suppress_deviation_count].to_i,
            current_groups_total[:valid_deviations_avg].to_i,
          ]
          
        end
      end
    
    end
  end

end