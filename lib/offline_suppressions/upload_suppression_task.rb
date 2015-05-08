class OfflineSuppressions::UploadSuppressionTask < ScheduledTask
  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config
    tasks = []
    jobs = TaskStatus.all(:conditions=>["task_status=? and class_name = ?","queued","OfflineSuppressions::UploadSuppressionTask"],
      :order=>:scheduled_timestamp)
    jobs.each do |t|
      tasks << self.new(t.task_name,t.scheduled_timestamp, 'n',t.id,t.params)
    end
    return tasks
  end

  attr_reader :name, :last_run_timestamp, :auto_retry, :queued_task_id, :params, :org
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id,params)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
    @queued_task_id = queued_task_id
    @params = params
    @org = Org.find(JSON.parse(@params)['org_id'])
  end

  def run
    params = JSON.parse(@params)

    errors =[]
    #email user with link to status page
    msg_subject="Suppression CSV Upload Process STARTED for #{org.org_name}, Group #{params['g']}"
    message = "Your request has begun to process.  You can follow the status using the link below"
    HipMailer.deliver_offline_suppressions(params['u'],@@config[:from],msg_subject,message,@queued_task_id,@params)

    begin

    # process csv files
    errors= OfflineSuppressions::SuppressionCsv.process(params)
    # Determine if any of the errors were critical
    critical_error = errors.find {|m| m =~ /^critical/i}
    # put errors in a file.  the errors are visible on the status page.
    file_name = File.join(APP['offline_suppression_files_path'], "#{params['fn']}.err")
    if errors.empty?
      File.delete(file_name) if File.exist?(file_name)
    else
      File.open(file_name, 'wb') do |file|
        errors.each {|error| file.puts error }
      end
    end
    msg_subject="Suppression CSV Upload Process COMPLETED for #{org.org_name}, Group #{params['g']}"
    message = "Your request has completed.  You can follow the status using the link at the end of this note"
    if errors.size > 0
      if critical_error
        message << "\n\nUpload Failed with the following errors:\n\n"
      else
        message << "\n\nUpload Succeeded with the following errors: \n\n"
      end
      errors.each {|m| message << "#{m}\n"}
    else
      message << "\n\nUpload Succeeded"
    end
    HipMailer.deliver_offline_suppressions(params['u'],@@config[:from],msg_subject,message,@queued_task_id,@params)
    {:success => true}
    
    rescue Exception => e
      msg_subject="Suppression CSV Upload Process Failed for #{org.org_name}, Group #{params['g']}"
      message = "Your request has failed.  Please save your suppression file and contact support"
      HipMailer.deliver_offline_message(params['u'],@@config[:from],msg_subject,message)      
      raise
    end

    # leaving the file alone for now.  we may need it for troubleshooting.
    # File.unlink("APP['offline_suppression_files_path']/#{params['fn']}")

  end
end