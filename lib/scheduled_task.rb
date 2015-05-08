class ScheduledTask

  class ScheduledTaskException <::Exception; end

  def self.get_task_objects(config, queued_tasks = [])
    # config is a hask generated from the YAML config file for this instance/class
    # queued_tasks is an array of queued or failed tasks, including their parameters
    #     queued_tasks is a hash or hash like object with the following keys:
    #        :task_id 
    #        :task_name
    #        :scheduled_timstamp
    #        :auto_retry
    #        :params
    # Subclasses are not required to use queued_tasks
    # Return an array of ScheduleTask object to be processed by ScheduledTaskRunner
    raise ScheduledTaskException, "get_task_objects not overridden in #{self.class}"
  end

  # The following is a list of methods that must be present
  # attr_reader :name, :last_run_timestamp, :auto_retry, :queued_task_id
  
  # Note:  In the classes that use this class as a super class, they will probably want to have an
  # accessor for params.  This accessor is not required for all classes and if used should be private

  def initialize(name, last_run_timestamp, auto_retry)
    # name is a string
    # last_run_timestamp can either be a Time object, or a string denoting a time
    #    In the case of queued jobs, last_run_timestamp > between the scheduled_timestamp (passed into get_task_objects) and
    #    less than the current timestamp.  Scheduled_timestamp pluss .1 second should work well
    raise ScheduledTaskException, "initialize not overridden in #{self.class}"
  end

  def run()
    # Run the task -- task will return an hash of {:success => boolean, :message => string}.  :message is not required on success
    raise ScheduledTaskException, "run not overridden in #{self.class}"
  end

  def name()
    raise ScheduledTaskException, "name not overridden in #{self.class}"
  end

  def last_run_timestamp()
    raise ScheduledTaskException, "last_run_timestamp not overridden in #{self.class}"
  end

  def auto_retry()
    raise ScheduledTaskException, "auto_retry not overridden in #{self.class}"
  end
  
  def queued_task_id()
    # Returns the task_id of a queued task that is being represented by this ScheduledTask object
    # Only tasks in the "queued" state have a queued_task_id
    raise ScheduledTaskException, "queued_task_id not overridden in #{self.class}"
  end

  def self.last_schedule_weekday_monthly (offset, hour, minute = 0, time_zone_name = 'Eastern Time (US & Canada)')
    # Basic approach -- Only work wtih times in the specified time zone to keep date consistant with the desired time zone.  
    # Remember that any times from 7:00 PM and later Easten Standard Time on the last day of the monty are not safe because
    # they may not be for the same month (8:00 during Daylight Savings Time).
    #
    # Set the time zone
    # Figure out when now is in the timezone
    # Move it to the end of the month (or beginning), beginning of day
    # If that is on a weekend, move it to the last (or first) weekday of the month
    # Move the date the number of weekdays necessary
    # If the time is in the future, move it back the by the interval and recaculate it
    # If the end result is not in the same month, rase an exception
    # return the time converted to GMT
    #
    # offset -- numeric.  Normally an integer.  Positive numbers indicate the number of weekdays from the beginning of the
    #     month, negative numbers indicate the number of weekdays from the end of the month.  Numbers less than zero
    #     indicate the beginning or end of the month depending on their sign.  The fractional part of the number is
    #     discarded, and is only allowed so that a sign can be provided to indicate which end of the month to caculate
    #     from.
    # hour -- numeric.  Specifies the hour of the day from 0 to 23
    # minute -- numeric.  Specifies the minute of the hour from 0 to 59.  Defaults to 0
    # time_zone_name -- string.  Specifies the name of the time zone for hour and minute, and the time zone for "now" to
    #     caculate the current date.  Must be one of the vaules returned by "Rake time:zones:all".  For a list of the
    #     time zones for the US, use "Rake time:zones:us".  Defaults to "Eastern Time (US & Canada)"
    time_zone_save = Time.zone
    begin
      Time.zone = time_zone_name
      now_tz = Time.zone.now
      from_end_of_month = offset < 0
      offset = offset.to_i
      if from_end_of_month
        # Make caculation from the end of the month
        end_of_month_tz = now_tz.end_of_month.beginning_of_day
        end_of_month_tz = -1.weekdays_from(end_of_month_tz) unless end_of_month_tz.weekday?   # Last weekday of month
        scheduled_time_tz = offset.weekdays_from(end_of_month_tz) + hour.hours + minute.minutes # Adjustment from the end of the month
        if scheduled_time_tz > Time.now  # if the scheduled time is in the future, back it up a month
          end_of_month_tz = (end_of_month_tz - 1.month).end_of_month.beginning_of_day
          end_of_month_tz = -1.weekdays_from(end_of_month_tz) unless end_of_month_tz.weekday? # Last weekday of previous month
          scheduled_time_tz = offset.weekdays_from(end_of_month_tz) + hour.hours + minute.minutes 
        end
      else
        # Same caculation if principle, but from the beginning of the month
        beginning_of_month_tz = now_tz.beginning_of_month.beginning_of_day
        beginning_of_month_tz = 1.weekdays_from(beginning_of_month_tz) unless beginning_of_month_tz.weekday?   # First weekday of month
        scheduled_time_tz = offset.weekdays_from(beginning_of_month_tz) + hour.hours + minute.minutes # Adjustment from the beginning of the month
        if scheduled_time_tz > Time.now  # if the scheduled time is in the future, back it up a month
          beginning_of_month_tz = (beginning_of_month_tz - 1.month).beginning_of_month.beginning_of_day
          beginning_of_month_tz = 1.weekdays_from(beginning_of_month_tz) unless beginning_of_month_tz.weekday? # First weekday of previous month
          scheduled_time_tz = offset.weekdays_from(beginning_of_month_tz) + hour.hours + minute.minutes 
        end
      end
      if scheduled_time_tz.month != scheduled_time_tz.utc.month
        raise ScheduledTaskException, "Requested Schedule #{scheduled_time_tz} is not in same month in both #{Time.zone.name} and UTC"
      end
    ensure
      Time.zone = time_zone_save
    end
    return scheduled_time_tz.utc
  end
  
  class <<self
    alias weekday_monthly last_schedule_weekday_monthly 
  end
  
  def self.last_schedule_daily(hour, minute = 0, weekdays_only = false, time_zone_name = 'Eastern Time (US & Canada)')
    #
    # hour -- numeric.  Specifies the hour of the day from 0 to 23
    # minute -- numeric.  Specifies the minute of the hour from 0 to 59.  Defaults to 0
    # weekdays_only -- boolean.  Specifies if the schedule is only to include weekdays
    # time_zone_name -- string.  Specifies the name of the time zone for hour and minute, and the time zone for "now" to
    #     caculate the current date.  Must be one of the vaules returned by "Rake time:zones:all".  For a list of the
    #     time zones for the US, use "Rake time:zones:us".  Defaults to "Eastern Time (US & Canada)"
    #
    # Note:  The caculation will not off by an hour on the day that Daylight Saving Time start and ends, but good enough for this
    #        method.  This of course does not affect times when weekdays_only is true
    #
    time_zone_save = Time.zone
    begin
      Time.zone = time_zone_name
      scheduled_time = Time.zone.now.beginning_of_day + hour.hours + minute.minutes
      scheduled_time = (1.weekdays_from(scheduled_time)).beginning_of_day + hour.hours +  minute.minutes if weekdays_only && !scheduled_time.weekday?
      if Time.now < scheduled_time
        scheduled_time = (scheduled_time - 1.day).beginning_of_day + hour.hours + minute.minutes
        scheduled_time = (-1.weekdays_from(scheduled_time)).beginning_of_day + hour.hours +  minute.minutes if weekdays_only && !scheduled_time.weekday?
      end
      if scheduled_time.day != scheduled_time.utc.day
        raise ScheduledTaskException, "Requested Schedule #{scheduled_time_tz} is not in same day in both #{Time.zone.name} and UTC"
      end
    ensure
      Time.zone = time_zone_save
    end
    return scheduled_time.utc
  end

end