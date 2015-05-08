class OfflineResetCurrentGroups < ScheduledTask
  
  def self.get_task_objects(config,queued_tasks = [])
    @@config = config
    # Runs on the 1st weekday of the month at 8:00 Eastern
    scheduled_time_et = ScheduledTask.weekday_monthly(0,8)

    # Return an array of ScheduleTask object to be processed by ScheduledTaskRunner
    # Note that the max size of the task name is 60 characters
    [self.new('reset_current_groups', scheduled_time_et, 'y',nil)]
  end
  
  attr_reader :name, :last_run_timestamp, :auto_retry,:queued_task_id
  
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
  end
  
  def run()
   
    hip_period = HipPeriod.find(SwareBase.current_period_id)
    scheduled_time_et = ScheduledTask.weekday_monthly(0,8)
    # Change any current HC groups to not current
    HcGroup.update_all({:is_current => 'n', :lu_userid => 'hip_application', :lu_timestamp => Time.now.utc}, 
      ["is_current = 'y' and lu_timestamp < ?",hip_period.asset_freeze_timestamp.beginning_of_month])
    return {:success => true}
  end
    
end