class Admin::CbnController < ApplicationController

  require_role 'Admin'

  def index
    @show_element="admin"
    @show_queue_button = allow_queueing?
  end

  def queue_task
    @show_element="admin"
    if !allow_queueing?
      flash[:error] = 'Operation not permitted, a job was queued in the last 24 hours'
      render :action => :index
    end
    TaskStatus.create({:instance_name=>'15minutes',
      :task_name=>"cbn_email_#{Time.now.to_i}",
      :task_status=>'queued',
      :class_name=>'ContinuedBusinessNeedMail',
      :auto_retry=>'n',
      :task_message=>"Send CBN e-mails",
      :start_timestamp=>Time.now,
      :scheduled_timestamp=>Time.now,
      :lu_userid=>current_user.userid,
      :params=>{
        'u'=>current_user.userid
        }.to_json
      })
  end

  def preview
    @show_element="admin"
    @mailing_list = ContinuedBusinessNeedMail.get_manager_list
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end

  #########
  private
  #########

  def allow_queueing?
    t = TaskStatus.find(:first, :conditions => "class_name = 'ContinuedBusnessNeedMail' and task_status not in ('crashed', 'failed') and scheduled_timestamp > current_timestamp - 1 day")
    return t.nil?
  end

end