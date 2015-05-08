class InfoWarningReportTask< ScheduledTask

  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config

    # Runs on the 2nd weekday from the last day of the month at 8pm eastern
    schedule_time_utc = ScheduledTask.last_schedule_weekday_monthly(-2,20,0,'Eastern Time (US & Canada)')

    tasks = []

    orgs = Org.service_hip
    orgs.each do |org|
      hc_groups = org.hc_groups.current
      hc_groups.each do |group|
        tasks << self.new("InfoWarn-#{org.org_id}-#{group.hc_group_id}",schedule_time_utc, 'y',nil, org,group)
      end
    end
    return tasks
  end

  attr_reader :name, :last_run_timestamp, :auto_retry, :queued_task_id, :org,:group

  def initialize(name, last_run_timestamp, auto_retry,queued_task_id,org,group)
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

    period = SwareBase.current_period
    org_name = @org.org_name.gsub(/\W/,"_")# replace space with underscore
    storage_path = "#{RAILS_ROOT}/reports/#{org_name}/#{period.asset_freeze_timestamp.strftime("%Y-%m")}"
    FileUtils.makedirs(storage_path)
    filename_params={
      :org_name=>org.org_name,
      :group_name=>@group.group_name,
      :report_num=>"152C-02",
      :extention=>"csv"
    }
    filename = FilenameCreator.filename(filename_params)
    params={
      :title=>"In-Cycle Final Information & Warning Details",
      :org_id=>"#{@org.org_l1_id},#{@org.org_id}",
      :hc_group_id=>@group.hc_group_id,
      :filename=>"#{storage_path}/#{filename}",
      :report_num =>"152C-02"
    }
    InfoWarningDetail.get_report(params)
  
    SwareBase.reset_period if override_date
    {:success => true}
  end




end