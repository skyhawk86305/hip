class Mhc::MhcTask < ScheduledTask
  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config
    tasks = []
    jobs = TaskStatus.all(:conditions=>["task_status=? and class_name=?","queued","Mhc::MhcTask"],
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

    # We don't put out a status message until the end of this scheduled task, when we have the task ID of the task that monitors the ETL
    # to use in the message.
    
    # create csv files
    errors = Mhc::MhcCsv.compact_flatten(MhcCsv.create_etl_file(params,@queued_task_id))
    
    if errors.empty?
      # no errors so far, create task to check for ETL work
      task = TaskStatus.create( { :instance_name=>'15minutes',
        :task_name=>"scan_insert_#{params['org_id']}_#{Time.now.to_i}",
        :task_status=>'queued',
        :class_name=>'Mhc::MhcCheckEtlTask',
        :auto_retry=>'n',
        :task_message=>"Scan insert for #{org.org_name} ",
        :start_timestamp=>Time.now,
        :scheduled_timestamp=>Time.now,
        :lu_userid=>params['u'],
        :params => { 'task_id'=>@queued_task_id, 'u'=>params['u'], 'org_id'=>params['org_id'], 'batch_status' => 'pending', 'fn' => params['fn'] }.to_json
        } )

      msg_subject="Generic Tool Upload process has Started for Account: #{org.org_name}, File: #{File.basename(params['fn'])}"
      message = "The first step of your request has completed.  You can verify the status from status page using the link below.  This is only the first step of a multiple step process.  The scan is NOT available yet.  You will receive another email when the scan is available."
      HipMailer.deliver_mhc_status(params['u'],@@config[:from],msg_subject,message,task.id,@@config[:host])
      
      status = 'succeeded'
    else
      # there were errors, so report the results to the user, but do not process this file any futher
      file = File.new("#{params['fn']}.err",'w')
      errors.each do |error|
        file.puts error
      end
      file.close

      msg_subject="Manual Scan Upload process has FAILED for #{org.org_name}, file #{params['fn']}"
      message = "The upload of file #{params['fn']} failed in the first step.  The scan was NOT loaded into HIP.  The uploaded file had the following errors:\n\n"
      errors.each {|m| message << "#{m}\n"}
      HipMailer.deliver_mhc_status(params['u'],@@config[:from],msg_subject,message,@queued_task_id,@@config[:host])
      
      status = 'failed'
    end
    
    # TODO remove uploaded file
    #File.unlink("#{params[:fn]}")
    
    {:success => true ,:message=>"Manual Scan Upload #{status}."}
  end

end