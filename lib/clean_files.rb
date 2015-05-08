# remove obsolete files from systems
class CleanFiles < ScheduledTask
  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config

    # This is to run once every weekday at midnight eastern
    schedule_time_utc = ScheduledTask.last_schedule_daily(0,0,false,'Eastern Time (US & Canada)')
    return [self.new("Clean Files",schedule_time_utc, 'y',nil)]
  end

  attr_reader :name, :last_run_timestamp, :auto_retry,:queued_task_id
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
  end

  def run
    clean_progress_report_files
    clean_offline_suppression_files
    {:success => true}
  end

  # remove interim HC Cycle report.
  def clean_progress_report_files
    Dir.glob("#{RAILS_ROOT}/tmp/hc_cycle_report.*") do |file|
      if 24.hours.ago > File.ctime(file)
        File.delete(file)
      end
    end
  end

  # remove uploaded suppression files
  def clean_offline_suppression_files
    Dir.glob("#{RAILS_ROOT}/tmp/suppression_*.*") do |file|
      if 24.hours.ago > File.ctime(file)
        File.delete(file)
      end
    end
    #delete downloadable files that are 7 days old
    Dir.glob("#{RAILS_ROOT}/reports/offline_suppression/*/suppression_*.csv") do |file|
      if 7.days.ago > File.ctime(file)
        File.delete(file)
      end
    end
  end
end