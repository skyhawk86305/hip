class ScheduledTest < ScheduledTask
  
#  def self.get_task_objects(config)
#    # Return an array of ScheduleTask object to be processed by ScheduledTaskRunner
#    # Note:  Be careful with dates.  Remember that the Date GMT may not be the same Date in a different Time Zone.
#    # 
#    # The main idea in the logic below is to determine when this should have run last -- the ScheduleTaskRunner will
#    # run the task if it hasn't already run the task for the schedule time.
#    #
#    # Save the config for use by other methods
#    RAILS_DEFAULT_LOGGER.debug "Setting up config"
#    @@config = config
#    # Determine the time for this month:  8:00 AM Eastern on the first weekday of the month
#    schedule_time_utc = Time.parse("#{Date.current.beginning_of_month} 08:00 AM America/New_York").utc
#    # Move schedule_time to a weekday if it isn't already one
#    schedule_time_utc = +1.weekdays_from(schedule_time_utc) unless schedule_time_utc.weekday?
#    # if the schedule time for this month is still in the future, return the scheduled time for last month
#    if schedule_time_utc > Time.now
#      schedule_time_utc = Time.parse("#{(Date.current - 1.month).beginning_of_month} 08:00 AM America/New_York").utc
#      schedule_time_utc = +1.weekdays_from(schedule_time_utc) unless schedule_time_utc.weekday?
#    end
#    # Return an array of new ScheduledTest objects that specify the name of the offline task (in this case, it's just using the class name),
#    # the schedule time of the last run, and the restartable flag.  If it is too late to run a specific task, do not return the item.
#    # returning an empty array is acceptable.
#    return [self.new('ScheduledTest', schedule_time_utc, 'y')]
#    
#    tasks = []
#    if Time.now - schedule_time_utc < 3 days
#      then
#        org_list = bla
#        org_list.each do |org|
#          ...
#          tasks < self.new('Audit1#org.org_name'[0...50],schedule_time, 'y', org)
#        end
#      end
#    return tasks
#  end
  
  def self.get_task_objects(config)
    # Return an array of ScheduleTask object to be processed by ScheduledTaskRunner
    # Note:  Be careful with dates.  Remember that the Date GMT may not be the same Date in a different Time Zone.
    # 
    # The main idea in the logic below is to determine when this should have run last -- the ScheduleTaskRunner will
    # run the task if it hasn't already run the task for the schedule time.
    #
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config
    # This is to run every other hour
    schedule_time_utc = Time.parse(Time.now.utc.strftime('%Y-%m-%d %H:00:00 %Z'))
    if schedule_time_utc.hour % 2 == 1
      schedule_time_utc -= 1.hour
    end
    # Schedule Time has to be in the past, so no need to check for it
    #
    # Return an array of new ScheduledTest objects that specify the name of the offline task (in this case, it's just using the class name),
    # the schedule time of the last run, and the restartable flag
    return [self.new('ScheduledTest', schedule_time_utc, 'y')]
  end
  
  attr_reader :name, :last_run_timestamp, :auto_retry
  
  def initialize(name, last_run_timestamp, auto_retry)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
  end
  
  def run
    HipMailer.deliver_offline_message(@@config[:to], @@config[:from], @@config[:subject], @@config[:message])
    #{:success => false, :message => "Testing a \"failed\" task"}
    {:success => true}
  end
    
end