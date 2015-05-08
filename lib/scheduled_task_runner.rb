class ScheduledTaskRunner

  # Assumptions:
  #   1) ScheduledTaskRunner will be invoked from cron via the console
  #   2) ScheduledTaskRunner will be invoked with the name of an instance
  #   3) ScheduledTaskRunner will use the instance name to look up that instance's configuration in a YAML config file
  #   4) The script that invokes ScheduledTaskRunner will never run (and will protect against) multiple simultaneous invocations with the same instance name
  #   5) ScheduledTaskRunner will be the only user of the TaskStatus model except for reporting
  #   6) ScheduledTaskRunner will run tasks that are sub-classes of ScheduledTask
  #   7) ScheduledTaskRunner will protect itself against exceptions thrown by a sub-class of ScheduledTask
  #   8) ScheduledTaskRunner will take extreem percautions to catch exceptions, and will exit with 'exit!(1) for any problem that
  #      results is an email not being sent by ScheduleTaskRunner

  class ScheduledTaskRunnerException <::Exception; end

  def self.run_tasks(instance = 'default')
    begin
      # Load Config
      scheduled_task_runner_filename = File.join(RAILS_ROOT, "config", "scheduled_task_runner.yml")
      scheduled_task_config = YAML::load(ERB.new(IO.read(scheduled_task_runner_filename)).result)
      global_config = scheduled_task_config[RAILS_ENV]
      error_to = global_config[:errors_to]
      error_from = global_config[:errors_from]
      error_reply_to = global_config[:errors_reply_to]

      instance_config = scheduled_task_config[RAILS_ENV + '_' + instance]
      if instance_config.nil?
        raise ScheduledTaskRunnerException, "No configuration for instance #{instance}"
      end
      classes = instance_config[:classes]
      if classes.nil?
        raise ScheduledTaskRunnerException, "No classes configured for instance #{instance}"
      end

      # Look for tasks that were running when we crashed (either system or application), and status them
      # This would be tasks that have a task_status of 'running'.  Since there can only be one instance with this name
      # running at a time, and we aren't currently running anything, any task for this instance must be left over from
      # a previous run.
      crashed_tasks = TaskStatus.find(:all, :conditions => {:instance_name => instance, :task_status => 'running'})
      crashed_tasks.each do |task_status|
        task_status.task_status = 'crashed'
        task_status.lu_userid = instance
        task_status.task_message = "Found crashed at #{Time.now.utc.to_s}"
        task_status.end_timestamp = Time.now.utc
        task_status.save!
      end

      # Loop through the task classes
      classes.each do |class_name|
        RAILS_DEFAULT_LOGGER.debug "ScheduledTaskRunner processing class #{class_name}"
        queued = TaskStatus.find(:all,:conditions=>["class_name=? and task_status='queued'",class_name])
        # Get the class to work with
        task_class = eval(class_name)
        # Get any config information for the class
        class_config = instance_config[class_name] || {}

        # Get array of task objects
        begin
          tasks = task_class.get_task_objects(class_config,queued)

          tasks.each do |task|
            task_name = task.name
            task_last_run_timestamp = task.last_run_timestamp
            # Has task not run yet?  -- look for previous instance_name/task_name/scheduled_timestamp that completed success -- that means don't run it
            # Also look for previous instace_name/task_name/scheduled_timestamp/failed with auto_retry == 'n' --  that means don't run
            previous = TaskStatus.find(:all, :conditions => ["instance_name = ? and task_name = ? and scheduled_timestamp = ? and (task_status = 'success' or (task_status in ('crashed', 'failed') and auto_retry = 'n'))", instance, task_name, task_last_run_timestamp])
            if previous.empty?
              # Status the task
              if task.queued_task_id.nil?
                task_status = TaskStatus.new(:instance_name => instance, :task_name => task_name, :scheduled_timestamp => task_last_run_timestamp, :auto_retry => task.auto_retry, :start_timestamp => Time.now.utc, :task_status => 'running', :lu_userid => instance)
                task_status.save!
              else
                task_status = TaskStatus.find(task.queued_task_id)
                task_status.update_attributes(:task_status=>'running',:start_timestamp=>Time.now,
                  :lu_userid=>instance)
              end

              # Run the task -- task will return an hash of {:success => boolean, :message => string}
              begin
                if task.respond_to? :org
                  Thread.current[:org_id] = task.org.id.join(',')
                end
                result = task.run
              rescue Exception => e
                task_name = defined?(task_name) ? task_name : 'no task name'
                message = "#{e.message}\n\n#{e.backtrace}\n"
                result = {:success => false, :message => "#{e.class}: #{message}"}
              end

              # Status the task
              if result[:success]==true
                task_status.task_status = 'success'
                task_status.end_timestamp = Time.now.utc
                task_status.task_message = result[:message].nil? ? nil : result[:message][0...TaskStatus.columns_hash["task_message"].limit]
              elsif result[:success]=="queued"
                task_status.task_status = 'queued'
                task_status.end_timestamp = nil
                task_status.task_message = result[:message].nil? ? nil : result[:message][0...TaskStatus.columns_hash["task_message"].limit]  
              else
                task_status.task_status = 'failed'
                task_status.end_timestamp = Time.now.utc
                task_status.task_message = result[:message].nil? ? nil : result[:message][0...TaskStatus.columns_hash["task_message"].limit]
                HipMailer.deliver_offline_error(error_to, error_from, error_reply_to, instance, task_name, result[:message])
              end
              task_status.params = result[:params].to_json unless result[:params].nil?
              task_status.save!

              # If the task failed with auto_retry 'y', leave it -- it will run the next time this instace is run from cron

            end # if previous.empty?

          end # tasks.each
        rescue Exception => e
          task_name = defined?(task_name) ? task_name : 'no task name'
          message = "#{e.class.to_s}: #{e.message}\n\n#{e.backtrace}\n"
          HipMailer.deliver_offline_error(error_to, error_from, error_reply_to, instance, task_name, message)
          RAILS_DEFAULT_LOGGER.error "Exception in task #{task_name}: message"
        end

      end # classes.each

    rescue Exception => e
      $stdout.sync = true
      puts e.class, e.message
      puts e.backtrace
      exit!(1)
    end # begin
    
    return nil
  end # def self.run_tasks

end # class