class HomeController < ApplicationController

  #
  # Disable the application level authentication for the "login" & "logout" actions of this controller
  # The filter is inherited from ApplicationController
  #
  skip_before_filter :authorization_filter, :only => [:login, :logout]
  #
  # Define permisssions needed beyond the default (of :authenticated)
  #
  # (none)

  def index
    @show_element="home"
    @paginate_ajax=''
    #(errors = ValidateHomeParameters.index(params)).each {|message| flash.now[:error] = message}
    #return nil unless errors.empty?
    # Note that the check above has been left here in case additional code needs to be added below
    #user = session[:credential][:user]
    #user = credential[:user]
    # current_user is a global variable from the application_controller.

    @orgs = org_list(params)
  end

  def select_new_org
    @paginate_ajax='pagination ajax'
    select_org
    @orgs = org_list(params)
    respond_to do |format|
      format.html
      format.js {
        render :update do |page|
          page.replace_html("current_org_name" , show_current_org_name)
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end

  def search_org
        @paginate_ajax='pagination ajax'
    include_org_conditions="(#{org_conditions(current_user.orgs_for_user)}) AND" unless org_conditions(current_user.orgs_for_user).blank?
    @orgs = Org.service_hip.paginate :all,
      :page=>params[:page],:conditions=>["#{include_org_conditions} LOWER(org_name) LIKE ?",  "%#{params[:org_name].downcase}%"],
      :order=>:org_name, :per_page=>params[:per_page]
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial=>'result'
        end
      }
    end
  end

  def login
    @show_element="home"
    @userid = cookies[:userid]

    if params[:userid]
      #(errors = ValidateHomeParameters.login(params)).each {|message| flash.now[:error] = message}
      #return nil unless errors.empty?
      
      cookies[:userid] = {:value => params[:userid], :expires => Time.now + 30.days} #30.days.from_now}
      if authenticated? || authenticate
        redirect_to ( return_to || { :controller => "/home", :action => "index" } )
      else
        flash.now[:error] = "Invalid userid or password"
      end
    else
      delete_credential # going to the login page will automatically log you out
    end
  end

  def logout
    #ValidateHomeParameters.logout(params).each {|message| flash.now[:error] = message}
    # even if someone tried to pass bad parameters, we are still going to log out this user
    delete_credential
    flash[:notice] = "Sign Out Complete"
    redirect_to(:action => "index")
  end

  private
  
  # build the conditions for a list of orgs the user
  # has authorization to see/use
  #
  def org_conditions(ids)
    if current_user.is_user_in_role?("GEO Focal") || current_user.is_user_in_role?("Admin")
      return nil # these roles should see everything
    end
    size=ids.size - 1
    condition = Array.new
    ids.each_with_index do |id,index|
      id=id.to_s
      id=id.split(',')
      condition.push("(org_l1_id=#{id[0]} and org_id=#{id[1]})")
      if size != index
        condition.push(" OR ")
      end
    end
    condition.join('')
  end

  # get the list of orgs for the home page.
  def org_list(params)
    Org.service_hip.paginate :all, :page=> params[:page],
      :conditions=>org_conditions(current_user.orgs_for_user),
      :order=>:org_name, :per_page=>params[:per_page]||=25
  end

end
