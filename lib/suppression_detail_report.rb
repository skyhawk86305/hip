class SuppressionDetailReport < ScheduledTask
  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config

    # This is to run at 1am eastern the first day of the month.
    schedule_time_utc = ScheduledTask.last_schedule_weekday_monthly(1,1,0,'Eastern Time (US & Canada)')
    return [self.new("SuppressionDetail",schedule_time_utc, 'y',nil)]
  end

  attr_reader :name, :last_run_timestamp, :auto_retry ,:queued_task_id

  def initialize(name, last_run_timestamp, auto_retry,queued_task_id)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
  end

  def run
    # Report runs from ScheduldTask
    # Default behavior is to run the report for the previous month
    # if override_date is  provided, the report runs for the month provided in :override_date
    #
    # Run the report manually,
    # ruby script/runner -e env "SuppressionDetailReport.get_task_objects({:override=>'2011-03-01'}).each {|t| t.run}"
    @report_timestamp = @@config[:override_date].blank? ? Time.now - 1.month : Time.parse(@@config[:override_date])

    @report_start_date = @report_timestamp.beginning_of_month
    @report_end_date = @report_timestamp.end_of_month
    @report_month_year = (@report_timestamp).strftime("%Y-%m")

    @storage_path = "#{RAILS_ROOT}/reports/#{@report_month_year}"
    FileUtils.makedirs @storage_path
    # create csv report
    csv_report
    # send message to scheduler
    {:success => true}
  end

 

  def csv_report()
    from_date =@report_start_date.strftime("%m/%d/%Y")
    to_date = @report_end_date.strftime("%m/%d/%Y")

    filename="#{@storage_path}/Suppression_Deviation_Detail_131C-01-#{@report_month_year}.csv"
    CSV.open(filename, 'wb') do |csv|
    
      csv << ["Suppression Deviation Detail Report"]
      csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << ["Report Period: From #{from_date} to #{to_date}"]
      csv << ["Report #: 131C-01"]
      csv << [nil] # create new line
      # create headers
      csv << [
        "Account",
        "Suppression Name",
        "Suppression Classification",
        "Start Date",
        "End Date",
        "Scan Type",
        "Tool Name",
        "# of Scans Released",
        "Number of Deviations Suppressed in Released Scan"
      ]
      params={:start_date =>@report_start_date.strftime("%Y-%m-%d %H:%M:%S.0"),
        :end_date=>@report_end_date.strftime("%Y-%m-%d %H:%M:%S.0")
      }
      results =  SuppressionDetailReportSearch.search(params)
      results.each do |result|

        csv << [
          result.org_name,
          result.suppress_name,
          result.suppress_class,
          result.start_timestamp,
          result.end_timestamp,
          result.scan_type,
          result.manager_name,
          result.scans_released_count,
          result.suppression_count
        ]
      
      end
    end
  end




end