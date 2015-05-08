class Admin::TaskStatusesController < ApplicationController
  require_role 'Admin'
  def index
    @task = TaskStatus.new
    #scheduled_task_runner_filename = File.join(RAILS_ROOT, "config", "scheduled_task_runner.yml")
    #scheduled_task_config = YAML::load(ERB.new(IO.read(scheduled_task_runner_filename)).result)
    #global_config = scheduled_task_config[RAILS_ENV]
      
  end

  def search
    session[:task_status]=params[:task_status]
    @tasks = TaskSearch.search(params[:task_status]).paginate :page => params[:page],
      :per_page => params[:task_status][:per_page]
    
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end
  
  def new
    @task = TaskStatus.new
  end
  
  def create
    @task = TaskStatus.new(params[:task_status])
    @task.lu_userid = current_user.userid
    respond_to do |format|
      if @task.save
        flash[:notice] = 'Task was successfully created.'
        format.html { redirect_to(:action=>"index") }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def edit
    @task = TaskStatus.find(params[:id])
    
  end
  
  def update
    @task = TaskStatus.find(params[:id])
    @task.lu_userid = current_user.userid
    respond_to do |format|
      if @task.update_attributes(params[:task_status])
        flash[:notice] = 'Task was successfully updated.'
        format.html { redirect_to(:action=>"index") }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    task = TaskStatus.find(params[:id])
    task.destroy
    respond_to do |format|
      format.html { redirect_to(admin_tasks_path) }
    end
  end
  
  def restart
    task = TaskStatus.find(params[:id])
    task.lu_userid = current_user.userid
    task.task_status = 'queued'
    #task.start_timestamp =nil
    #task.end_timestamp = nil
    
    respond_to do |format|
      if task.update_attributes(params[:task_status])
        flash[:notice] = 'Task was successfully restarted.'
        @tasks = TaskSearch.search(session[:task_status]).paginate :page => params[:page],
          :per_page => session[:task_status][:per_page]
        format.js {
          render :update do |page|
            page.replace_html 'result', :partial => 'result'
          end
        }
      else
        @tasks = TaskSearch.search(session[:task_status]).paginate :page => params[:page],
          :per_page => session[:task_status][:per_page]
        flash[:notice] = 'Task was not restarted.'
        format.js {
          render :update do |page|
            page.replace_html 'result', :partial => 'result'
          end
        }
      end
    end
  end

  def destroy
    task=TaskStatus.find(params[:id])
    task.destroy
    
    @tasks = TaskSearch.search(session[:task_status]).paginate :page => params[:page],
      :per_page => session[:task_status][:per_page]
    flash[:notice] = 'Task was not restarted.'
    
      render :update do |page|
        page.replace_html 'result', :partial => 'result'
      end
    
  end
  
end
