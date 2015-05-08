class HcCycleValidDeviationTrackingTemplate
  
  def self.get_task_objects(config,queued_tasks = [])
    @@config = config
    # TODO get schedule time from period table (new column)
    # TODO move query for groups to here and modify so that there is a seperate job for each customer or group
    return [self.new('ValidDeviationsReport', Time.now.utc, 'y',nil)]
  end
  
  attr_reader :name, :last_run_timestamp, :auto_retry,:queued_task_id
  
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id)
  end
  
  def run()
    override_date = @@config[:override_date]
    SwareBase.set_period(override_date) if override_date
    
    # Output a status message in case anyone is watching
    puts "Override Date: #{SwareBase.HcCycleAssetFreezeTimestamp.strftime("%m-%d-%Y")}"
        
    # TODO:  Put application into read only mode
    
    # TODO:  When date is overriden, this should be for all accounts. -- or a list of groups
    # Get groups active HC Cycle groups from orgs subscribed to HIP
    groups = HcGroup.find_all_current_groups
    
    groups.each do |group|
      puts "Processing Org \"#{Org.find([group.org_l1_id, group.org_id]).org_name}\", group \"#{group.group_name}\""
      self.class.valid_deviations_report(group)
    end
    
    # TODO: Take application out of read only mode
    
    
    SwareBase.reset_period if override_date
    {:success => true}
  end
  
  def self.valid_deviations_report(group)
    hc_group_id = group.hc_group_id
    group_name=group.group_name.gsub(/\W/,"_")
    period = SwareBase.current_period
    org_id = "#{group.org_l1_id},#{group.org_id}"
    org = Org.find(org_id)
    org_name = org.org_name.gsub(/\W/,"_")
    storage_path = "#{RAILS_ROOT}/reports/#{org_name}/#{period.asset_freeze_timestamp.strftime("%Y-%m")}"
    filename="#{storage_path}/#{org_name}_#{group_name}_#{period.asset_freeze_timestamp.end_of_month.strftime("%m-%d-%Y")}_Cycle_End_Valid_Deviations_Tracking_Document.csv"

    deviations = DeviationSearch.search(
      {"hc_group_id"=>hc_group_id,
        "org_id"=>org_id,
        "val_group"=>"all",
        "val_status"=>'valid',
        "ip_address"=>nil,
        "vuln_title"=>nil,
        "vuln_text"=>nil,
        "suppress_id"=>nil,
        "os"=>nil,
        "host_name"=>nil,
        "not_released"=>"no",
        "scan_id"=>nil,
        "order"=>"host_name,validation_status,suppress_class,suppress_name"
      },0,2)
    count = deviations.size == 0 ? 0 : deviations.first.count

    per_page=64000
    if count < per_page
      per_page=count
    end
    if count > 0
      pages = (count.to_i / per_page.to_i)+1
    else
      pages =1  # create atleast one page, with headers, but no results
    end

    FileUtils.makedirs(storage_path)
    outfile = File.open(filename, 'wb')
    CSV.open(outfile) do |csv|
      csv << ["Cycle End Valid Deviation Tracking Template"]
      csv << ["Report for Health Check Cycle Month ENDING #{Date.new(period.year,period.month_of_year,-1).strftime("%m/%d/%Y")}"]
      csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << [nil] # create new line
      csv << ["Account: #{org.org_name}"]
      csv << ["Customer (CHIP) ID: #{org.org_ecm_account_id}"]
      csv << ["All Data Based on Inventory Locked as of: #{period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << ["HC Cycle Group: #{group.group_name}"]
      csv << [nil] # create new line
      csv << ["NOTE: Only Valid Deviations from RELEASED scans are included in this tracking document."]
      # create headers
      csv << [
        "System Name",
        "Scan Date",
        "Scan Tool",
        "Deviation Validation Group",
        "Deviation Level",
        "Deviation Text",
        "Deviation Status",
        "Fix Time (# of calendar days)",
        "Remediation Due Date",
        "Remediation Team",
        "CIRATS NCI #",
        "SA Name",
        "Change Record (CR) #",
        "CR Implementation date",
        "*NEW* False Positive? (Y.N)",
        "How *NEW* FP Verified"
      ]
      pages.times do |page|
        page +=1 # need to start with 1
        to=per_page*page
        from=(to-per_page)+1
        results = DeviationSearch.search(
          {"hc_group_id"=>hc_group_id,
            "org_id"=>org_id,
            "val_group"=>"all",
            "val_status"=>'valid',
            "ip_address"=>nil,
            "vuln_title"=>nil,
            "vuln_text"=>nil,
            "suppress_id"=>nil,
            "os"=>nil,
            "host_name"=>nil,
            "not_released"=>"no",
            "scan_id"=>nil,
            "order"=>"host_name,validation_status,suppress_class,suppress_name"
          },from, to)

        results.each do |result|
          csv << [
              result.host_name,
              result.scan_start_timestamp,
              result.manager_name,
              result.cat_name.nil? ? result.sarm_cat_name : result.cat_name,
              result.deviation_level,
              result.finding_text,
              result.validation_status,

              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
            ]
        end
      end
    end
    outfile.close
  end # self.valid_deviations_report
  
end
  