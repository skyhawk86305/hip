class TaskStatusController < ApplicationController

  def show
    
    begin
      @task = TaskStatus.find(params[:id])
      unless @task.nil?
        @task_params = @task.params.nil? || @task.params == "null" ? {} : JSON.parse(@task.params)
        @org = @task_params['org_id'].nil? ? nil : Org.find(@task_params['org_id'])
        @errors = []
        @task_status = @task.task_status
        @task_message = @task.task_message

        # when the MHC ETL is done, check the status and get the errors.
        if @task.class_name == 'Mhc::MhcCheckEtlTask' and @task.task_status=='success'
          (status, @task_status, @task_message, @message_subject, @message) = Mhc::MhcCheckEtlTask.task_status(@task_params['task_id'], @org, @task_params)
          @message = @message.gsub(/\n/, "<br/>")
        else
          # Classes other than MhcCheckEtlTask
          @errors = []
          file_name = File.join(APP['offline_suppression_files_path'], "#{@task_params['fn']}.err")
      		if File.exists?(file_name)
      			@errors = File.open(file_name) {|error_file| error_file.readlines() }
      		end
        	critical = @errors.find {|m| m =~ /^critical/i }
      		if @task.task_status == 'success' && critical
            @task_status = 'Failed'
      		elsif @task.task_status == 'success' && !@errors.empty?
            @task_status = 'Success With Errors'
      		else
            @task_status = @task_status.titleize
      		end
          @message_subject = @errors.empty? ? "No Errors Found" : "The following errors occured:<br/>"
          @message = @errors.join('<br/>')
        end
      end # if @task.nil?
    rescue ActiveRecord::RecordNotFound
      flash.now[:error]="Task Id #{params[:id]} was not found"
      render :action=>:show
    end
  end

  def get_file
    storage_path = File.join(RAILS_ROOT, "reports")
    send_file File.join(storage_path, params[:file]),
      :type => 'text/csv; charset=iso-8859-1',
      :disposition => "attachment"
  end
end
