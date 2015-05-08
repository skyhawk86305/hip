class OfflineSuppressions::DownloadSuppressionTask < ScheduledTask
  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config
    tasks = []
    jobs = TaskStatus.all(:conditions=>["task_status=? and class_name=?","queued","OfflineSuppressions::DownloadSuppressionTask"],
      :order=>:scheduled_timestamp)
    jobs.each do |t|
      tasks << self.new(t.task_name,t.scheduled_timestamp, 'n',t.id,t.params)
    end
    return tasks
  end

  attr_reader :name, :last_run_timestamp, :auto_retry, :queued_task_id, :params, :org, :qp
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id,params)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
    @queued_task_id = queued_task_id
    @params = params
    @qp = YAML.load_file("#{RAILS_ROOT}/tmp/"+JSON.parse(@params)['qp'])
    @org = Org.find(qp['org_id'.to_sym])
  end

  def run
    params = JSON.parse(@params)
    
    create_csv_params = {:deviation_search=>qp,
      :filename=>params['fn'],
      :s=>params['s'],
      :g=>params['g'],
      :st=>params['st']
      }
    
    
    # TODO email user with status
    msg_subject="Suppression CSV download process has STARTED for #{org.org_name}, Group #{params['g']}"
    message = "Your request has begun processing.  You can follow the status using the link below"
    HipMailer.deliver_offline_suppressions(params['u'],@@config[:from],msg_subject,message,@queued_task_id,@params)
    #include link to task info

    # create csv files
    OfflineSuppressions::SuppressionCsv.create_csv(create_csv_params)
    
    msg_subject="Suppression CSV download process has COMPLETED for #{org.org_name} Group #{params['g']}"
    message = "Your request has completed.  You can download the file from the status page using the link below."
    HipMailer.deliver_offline_suppressions(params['u'],@@config[:from],msg_subject,message,@queued_task_id,@params)

    # TODO remove tmp file
    File.unlink("#{RAILS_ROOT}/tmp/"+params['qp'])
    {:success => true}
  end




end