class Mhc::MhcCheckEtlTask < ScheduledTask
  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config
    tasks = []
    jobs = TaskStatus.all(:conditions=>["task_status=? and class_name=?","queued","Mhc::MhcCheckEtlTask"],
      :order=>:scheduled_timestamp)
    jobs.each do |t|
      tasks << self.new(t.task_name, t.scheduled_timestamp, 'n', t.id, t.params)
    end
    return tasks
  end

  attr_reader :name, :last_run_timestamp, :auto_retry, :queued_task_id, :params, :org
  def initialize(name, last_run_timestamp, auto_retry, queued_task_id, unparsed_params)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
    @queued_task_id = queued_task_id
    @params = unparsed_params
    @org = Org.find(JSON.parse(unparsed_params)['org_id'])
  end

  def run

    parsed_params = JSON.parse(@params)
    orig_task_id = parsed_params['task_id']
    
    (status, batch_status, task_message, msg_subject, message) = self.class.task_status(orig_task_id, @org, parsed_params)
    
    parsed_params['batch_status'] = batch_status
    
    if status == true
      message.gsub!(/<br\/>/, "\n")
      HipMailer.deliver_mhc_status(parsed_params['u'], @@config[:from], msg_subject, message, @queued_task_id, @@config[:host])
    end
    
    return {:success => status ,:message=>task_message, :params => parsed_params}
  end

  def self.task_status(task_id, org, parsed_params)
    # returns [status, batch_status, task_message, message_subject, message]
    
    status = 'unknown'
    batch_status = 'unknown'
    task_message = nil
    message_subject = nil
    message = nil

    scan_post_transform_main_id = MetaProcess.scan_post_tranform_main[0].process_id
    scan_post_transform_per_server_id = MetaProcess.scan_post_tranform_per_server[0].process_id
    generic_scan_transform_id = MetaProcess.generic_transform[0].process_id

    etl = MetaProcessAudit.find(:first, 
    :conditions => {:external_batch_id => task_id, 
      :external_batch_system => 'HIP', :process_id => scan_post_transform_main_id}
    )
    if etl.nil?
      #
      # Check to see if the generic scan transform failed to produce any recores
      exception_table_name = MetaProcessAuditException.table_name
      etl = MetaProcessAudit.find(:first, 
        :select => "a.*", 
        :joins => "as a join #{exception_table_name} as e on e.audit_id = a.audit_id", 
        :conditions => ["a.external_batch_id = ? and e.rule_result_details like 'All records failed%'", task_id])
      if etl.nil?
        # if we didn't find a record, it isn't done
        status='queued'
        task_message="Scan insert process not started yet."
      else
          # if we find a record, there won't be any output from scan post transform, so the upload has failed
          message_subject = "Scan insert process has FAILED for Account: #{org.org_name}, File: #{File.basename(parsed_params['fn'])}"
          message = "An unexpected error has occured.  NO scans were created.<br/><br/>Please report this problem to the support group"
          etl_status = "Failed"
    end
    else
      #
      # We have ETL Status - So use it to update the message
      #
      if etl.status.downcase=='started'
        status="queued"
        batch_status = 'running'
        task_message = "Scan insert process is running."
        message_subject = nil
        message = nil
      elsif etl.status.downcase=='finished' or etl.status.downcase=='failed'
        info_exceptions = MetaProcessAuditException.find(:all,
          :conditions => ["audit_id = ? and log_type = 'info' and rule_result_details like 'finished scan_post_transform successfully%'",
            etl.audit_id])
        scans_id = info_exceptions.map {|e| /_scanid-(\d+)_/ =~ e.rule_result_details; $1}
        scans = []
        scans = AssetScan.find(:all, :conditions => "scan_id in (#{scans_id.join(',')})") unless scans_id.empty?
        assets_id = scans.map {|s| s.asset_id}
        assets_name = []
        assets_name = Asset.find(:all, :conditions => "row_to_timestamp is null and tool_asset_id in (#{assets_id.join(',')})") unless assets_id.empty?
        host_names = assets_name.map{|a| a.host_name}
        errors = etl.meta_process_audit_exceptions.find(:all, :conditions => {:log_type => 'error'})
        etl_status = "unknown"
        
        if etl.status.downcase == 'failed' || (info_exceptions.empty? && !errors.empty?)
          # No scans created, but there are error messages
          message_subject = "Scan insert process has FAILED for Account: #{org.org_name}, File: #{File.basename(parsed_params['fn'])}"
          message = "NO scans were created\n\n"
          etl_status = "Failed"
        elsif  info_exceptions.size == host_names.size && errors.empty?
          # All scans created, no error messages
          message_subject = "Scan insert process has completed for Account: #{org.org_name}, File: #{File.basename(parsed_params['fn'])}"
          message = "#{host_names.size} out of #{info_exceptions.size} scans were created<br/><br/>"
          message << "Scans were created for the following hosts:\n"
          host_names.each {|h| message << "#{h}<br/>"}
          etl_status = "Completed"
        elsif info_exceptions.size == host_names.size && !errors.empty?
          # All scans created, but there are error messages -- probably rejected rows
          message_subject = "Scan insert process has completed with ERRORS for Account: #{org.org_name}, File: #{File.basename(parsed_params['fn'])}"
          message = "#{host_names.size} out of #{info_exceptions.size} scans were created<br/><br/>"
          message << "Scans were created for the following hosts:\n"
          host_names.each {|h| message << "#{h}<br/>"}
          etl_status = "Completed with Errors"
        elsif info_exceptions.size != host_names.size && !errors.empty?
          # Some scans created -- errors messages may either be about rejected rows, or rejected scans
          message_subject = "Scan insert process has completed with ERRORS for Account: #{org.org_name}, File: #{File.basename(parsed_params['fn'])}"
          message = "#{host_names.size} out of #{info_exceptions.size} scans were created<br/><br/>"
          message << "Scans were created for the following hosts:\n" unless host_names.empty?
          host_names.each {|h| message << "#{h}<br/>"}
          etl_status = "Completed with Errors"
        else
          # A Situation has occured that shouldn't occure -- like all scans not being create but no error messages
          message_subject = "Scan insert process has FAILED for Account: #{org.org_name}, File: #{File.basename(parsed_params['fn'])}"
          message = "This is an process failure and should be reported to the support group"
          etl_status = "Failed"
        end
        
        errors.each do |e| 
          if e.rule_reference_row_number == 0
            message << "\n#{e.rule_result_details.gsub(/^org_l1: \d+ org: \d+ /, '')}"
          else
            message << "\n#{e.rule_result_details.gsub(/^org_l1: \d+ org: \d+ /, '')} Column #{e.rule_reference_col_name} Line# #{e.rule_reference_row_number}"
          end
        end

        batch_status = etl_status
        status = true # etl complete
        task_message = "Scan insert process #{etl_status}."
      else
        #
        # The ETL status isn't understood -- be vague
        status='queued'
        task_message="Scan insert process is running."
      end
    end
    return [status, batch_status, task_message, message_subject, message]
  end
  
end