class HcCycleReport < ScheduledTask

  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config

    #run two days before the last day of the month at 10pm ET, 8pm MT.
    schedule_time_utc = ScheduledTask.last_schedule_weekday_monthly(-2,22,0,'Eastern Time (US & Canada)')

    tasks = []

    orgs = Org.service_hip
    orgs.each do |org|
      hc_groups = org.hc_groups.current
      hc_groups.each do |group|
        tasks << self.new("HcCycleAudit-#{org.org_id}_#{group.hc_group_id}",schedule_time_utc, 'y',nil, org,group)
      end
    end
    return tasks

  end

  attr_reader :name, :last_run_timestamp, :auto_retry,:queued_task_id,:org,:group
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id,org, group)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
    @org = org
    @group = group
  end

  def run
    override_date = @@config[:override_date]
    SwareBase.set_period(override_date) if override_date
    @org_name = org.org_name.gsub(/\W/,"_") #replace / with - (for date indicator)
    @period = SwareBase.current_period
    # TODO:  Need to base filename off the release month -- not the current time.
    @storage_path = "#{RAILS_ROOT}/reports/#{@org_name}/#{@period.asset_freeze_timestamp.strftime("%Y-%m")}"
    FileUtils.makedirs @storage_path

    # Process all scans with findings
    result = get_deviations( @org.id.to_s, @group.hc_group_id, 0,2)
    count = result.size == 0 ? 0 : result.first.count
    dir = "#{rand(100000)}-#{@org_name}-#{@group.hc_group_id}" # create unique dir name
    @zip_path = "#{RAILS_ROOT}/tmp/#{dir}"
    Dir.mkdir(@zip_path) # create only if there are files to build
    file = 0
    if count>0    
      per_file=64000
      files = (count.to_i/per_file.to_i)+1
      files.times do |i|
        file += 1 # start with 1
        to=per_file*file
        from=(to-per_file)+1
        results = get_deviations(@org.id.to_s, @group.hc_group_id,from,to)
        # create pdf report and zip file
        pdf_report results, @org, @group.group_name.strip, file

        #generate the csv for each hc_group
        csv_report results, @org, @group.group_name.strip,file
      end
    end
    # Process any clean scans -- they were not accounted for above
    results = DeviationSearch.get_latest_released_clean_scans(@org.id.to_s, @group.hc_group_id)
    if results.size > 0
      file += 1
      pdf_report results, @org, @group.group_name.strip, file
      csv_report results, @org, @group.group_name.strip,file
    end
    # remove tmp dir for zip creation.
    FileUtils.rm_rf(@zip_path)
    
    SwareBase.reset_period if override_date
    {:success => true}
  end

  def pdf_report(results,org,group_name,file)
    #Dir.chdir(RAILS_ROOT)
    # create hash of host_name for the table
    data=Hash.new()
    #org_group_name = group_name
    group_name=group_name.gsub(/\W/,"_")
    results.each do |h|
      data[h.host_name] ||= [
        [ "<th>Scan Tool</th>",
          "<th>Deviation Level</th>",
          "<th>Finding / Deviation Text</th>",
          "<th>Deviation Validation Group</th>",
          "<th>Deviation Status</th>",
          "<th>Suppression Classification</th>",
          "<th>Suppression Name</th>"]]
      if h[:manager_name]
        data[h.host_name] <<[
          "<td valign='top'><div class='nobreak'>#{h.manager_name.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{h.deviation_level.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{h.finding_text.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{h.cat_name.nil? ? h.sarm_cat_name.to_s : h.cat_name.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{h.validation_status.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{h.suppress_class.to_s}</div></td>",
          "<td valign='top'><div class='nobreak'>#{h.suppress_name.to_s}</div></td>"
        ]
      else
        data[h.host_name] << []
      end
    end
    host_name = nil
    results.each do |result|
      if host_name!=result.host_name
        filename="#{@zip_path}/#{@org_name}_#{group_name}_#{result.host_name.gsub('.','_')}_#{Date.new(@period.year,@period.month_of_year,-1).strftime("%m-%d-%Y")}_Cycle_End_HC_Cycle_Report_#{file}.html"
        fileHtml = File.new(filename, "w+")
        fileHtml.puts "<html>"
        fileHtml.puts "<head>"
        fileHtml.puts "<title>Cycle End HC Cycle Report</title>"
        fileHtml.puts "<style>"
        fileHtml.puts ".nobreak { page-break-inside: avoid;}"
        fileHtml.puts "</style>"
        fileHtml.puts "</head>"
        fileHtml.puts "<body>"
        fileHtml.puts "<p style='text-align:center'>"
        fileHtml.puts "<b>Health Check Cycle Audit Report</b><br/>"
        fileHtml.puts "<b>Report for Health Check Cycle Month ENDING</b> #{Date.new(@period.year,@period.month_of_year,-1).strftime("%m/%d/%Y")}<br/>"
        fileHtml.puts "<b>Report Run Date:</b> #{Time.now.utc.strftime("%m/%d/%Y %H:%M")} UTC<br/>"
        fileHtml.puts "</p>"
        fileHtml.puts "<p style='text-align:left'>"
        fileHtml.puts "<b>Account:</b> #{org.org_name}<br/>"
        fileHtml.puts "<b>Customer ID:</b> #{org.org_ecm_account_id}<br/>"
        fileHtml.puts "<b>All Data Based on Inventory Locked as of:</b> #{@period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC<br/>"
        fileHtml.puts "<b>HC Cycle Group:</b> #{@group.group_name}<br/>"
        fileHtml.puts "<b>System Scan Date:</b> #{result.scan_start_timestamp}<br/>"
        fileHtml.puts "<b>System Name:</b> #{result.host_name}<br/>"
        fileHtml.puts "</p>"
        fileHtml.puts "<table style='border: 1px solid black;' rules='all' cellpadding='3px'>"

        data[result.host_name].each do |cell|
          if cell.size != 0
            fileHtml.puts "<tr>"
            fileHtml.puts "#{cell[0]}"
            fileHtml.puts "#{cell[1]}"
            fileHtml.puts "#{cell[2]}"
            fileHtml.puts "#{cell[3]}"
            fileHtml.puts "#{cell[4]}"
            fileHtml.puts "#{cell[5]}"
            fileHtml.puts "#{cell[6]}"
            fileHtml.puts "</tr>"
          else
            fileHtml.puts "<td valign='top' colspan=7><div class='nobreak'>Health check scanner reported zero deviations for this labeled scan</td>"
          end
        end
        fileHtml.puts "</table>"
        fileHtml.puts "</body></html>"
        fileHtml.close()
        kit = PDFKit.new(File.new(filename),
          :header_left => "Account: #{org.org_name} System Name: #{result.host_name}"
        )
        kit.to_file("#{@zip_path}/#{@org_name}_#{group_name}_#{result.host_name.gsub('.','_')}_#{Date.new(@period.year,@period.month_of_year,-1).strftime("%m-%d-%Y")}_HC_Cycle_Audit_Report_#{file}.pdf")
      end
      host_name=result.host_name

    end

    zip_filename="#{@storage_path}/#{@org_name}_#{group_name}_#{Date.new(@period.year,@period.month_of_year,-1).strftime("%m-%d-%Y")}_Cycle_End_HC_Cycle_Report.zip"
    # remove the file, and recreate it if it exists
    if File.exist?(zip_filename)
      File.delete(zip_filename)
    end

    Dir.chdir(@zip_path)
    ::Zip::ZipFile.open(zip_filename, Zip::ZipFile::CREATE) {
      |zipfile|
      Dir.glob("*.pdf"){|file|
        zipfile.add(file,file)
      }
      zipfile.close
    }
    Dir.chdir("#{RAILS_ROOT}")
  end

  def csv_report(results,org, group_name,file)
    group_name=group_name.gsub(/\W/,"_")
    filename="#{@storage_path}/#{@org_name}_#{group_name}_#{Date.new(@period.year,@period.month_of_year,-1).strftime("%m-%d-%Y")}_Cycle_End_HC_Cycle_Report_#{file}.csv"
    CSV.open(filename, 'wb') do |csv|

      csv << ["Cycle End HC Cycle Audit Report"]
      csv << ["Report for Health Check Cycle Month ENDING #{Date.new(@period.year,@period.month_of_year,-1).strftime("%m/%d/%Y")}"]
      csv << ["Report Run Date: #{Time.now.utc.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << [nil] # create new line
      csv << ["Account Name: #{org.org_name}"]
      csv << ["Customer (CHIP) ID: #{org.org_ecm_account_id}"]
      csv << ["All Data Based on Inventory Locked as of: #{@period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << ["HC Cycle Group: #{group_name}"]
      csv << [nil] # create new line
      # create headers
      csv << [
        "System Name",
        "Scan Date",
        "Scan Tool",
        "Deviation Level",
        "Finding / Deviation Text",
        "Deviation Validation Group",
        "Deviation Status",
        "Suppression Classification",
        "Suppression Name",
      ]
      results.each do |result|
        csv << [
          result.host_name,
          result.scan_start_timestamp,
          result[:manager_name],
          result[:deviation_level],
          result[:title].nil? ? "Health check scanner reported zero deviations for this labeled scan" : result.finding_text,
          result[:cat_name].nil? ? result[:sarm_cat_name] : result[:cat_name],
          result[:validation_status],
          result[:suppress_class],
          result[:suppress_name]
        ]
      end
    end
  end

  def get_deviations(org_id, hc_group_id,from, to)
    return DeviationSearch.search(
      {"hc_group_id"=>hc_group_id,
        "org_id"=>org_id,
        "val_group"=>"all",
        "val_status"=>'all',
        "ip_address"=>nil,
        "vuln_title"=>nil,
        "vuln_text"=>nil,
        "suppress_id"=>nil,
        "os"=>nil,
        "host_name"=>nil,
        "not_released"=>'no',
        "latest_released"=>"true",
        'clean_scans'=>"yes",
        "scan_id"=>nil,
        "order"=>"host_name asc,validation_status asc,suppress_class asc,suppress_name asc"
      },from, to)
  end


end