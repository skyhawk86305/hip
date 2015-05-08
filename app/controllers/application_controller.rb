# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  # fix the fieldsWithErrors, replace div with span
  #ActionView::Base.field_error_proc = Proc.new { |html_tag, instance|
  #  "<span class=\"fieldWithErrors\">#{html_tag}</span>"}
  # Make the AuthenticationLogin module part of this application
  include AuthorizationLogin
  require 'auth_via_config'
  require 'auth_via_blue_pages'
  helper_method :user_has_role
  
  # Turn sessions off in authentication if the formation is xml or yaml
  # TODO:  Find how why req.format.xml? returns true when running under passenger
  # NOTE:  The following line was changed to accommodate passenger.
  #use_sessions_in_authentication Proc.new {|req, p| !(req.format.xml? || req.format.yaml?) }
  use_sessions_in_authentication Proc.new {|req, p| true }

  # Require role ":authenticated" to access all controllers & actions unless specifically
  # overriden

 RAILS_DEFAULT_LOGGER.debug "ApplicationController:: ABOUT TO CALL require_role"
  require_role(Role.find(:all, :order=> 'role_name').map {|role| role[:role_name]}, :match_any => true, :name => :authorization_filter)
 RAILS_DEFAULT_LOGGER.debug "ApplicationController::RETURNED From require_role"

  # Store the current user, org_l1_id and org_id in a Thread variable so that it can be retrived by model code
  before_filter do |controller|
    Thread.current[:current_user] = controller.current_user
    Thread.current[:org_id] = controller.current_org_id
  end
  # clear the search session params
  before_filter :clear_search_sessions, :except=>[:update,:destroy,:restart]
  ##################################
  # Catch these expected exceptions
  ##################################
  rescue_from AuthorizationLogin::NotAuthorized, :with => :not_authorized
  rescue_from AuthorizationLogin::NotAuthenticated, :with => :not_authenticated
  
  #before_filter do |controller|
  #  unavailable_url = "/unavailable.html"
  #  controller.respond_to do |format|
  #    format.html {
  #      controller.method(:redirect_to).call unavailable_url
  #    }
  #    format.js {
  #      controller.method(:render).call :update do |page|
  #        page.redirect_to unavailable_url
  #      end          
  #    }
  #  end
  #end


  def current_user
    credential[:user]
  end
  helper_method :current_user
  
  def current_org_id
    session[:org_id]
  end
  helper_method :current_org_id

  def current_org_name
    current_org ? current_org.org_name : "None Selected"
  end
  helper_method :current_org_name

  def ooc_group_id
    session[:ooc_group_id].to_i
  end
  helper_method :ooc_group_id
  def hc_group_id
 RAILS_DEFAULT_LOGGER.debug "ApplicationController::hc_group_id CALLED - peforming to_i"
    session[:hc_group_id].to_i
  end
  helper_method :hc_group_id
  
  def ooc_scan_type
    session[:ooc_scan_type]
  end
  helper_method :ooc_scan_type

  def per_page
    session[:per_page]
  end
  helper_method :per_page

  # if the org is not set
  # redirect back to the home page.
  def has_current_org_id
    if ! current_org_id
      flash[:notice]="Please select an account."
  RAILS_DEFAULT_LOGGER.debug "ApplicationController::has_current_org_id FAILED NO ORG_ID*** redirect to home controller"
      redirect_to :controller=>'/home'
    end
  end

  def edit_authorization
    if check_authorization==true
  RAILS_DEFAULT_LOGGER.debug "ApplicationController::edit_authorization RETURING failed_access"
      return failed_access 
    else
      return
    end
  end
  
  
  # used to hide/disable gui elements from views
  # user must be admin or in Role for Org
  # Deviation SME
  #
  def hide_element
    return check_authorization
  end
  helper_method :hide_element
  
  # put the selected org in session for use later.
  def select_org
    if params[:current_org_id]
      session[:org_id]=params[:current_org_id]
    end
  end
  helper_method :select_org

  # remove sessions used by pagination in filter results
  # to use existing filter options in the query.
  # they are not valid once the user navigates way from the search results.
  def clear_search_sessions
    session[:scan_search]=nil
    session[:asset_search]=nil
    session[:deviation_search]=nil
    session[:publish_scan_search]=nil
    session[:missed_scan_search]=nil
    session[:ooc_group_search]=nil
    session[:ooc_asset_search]=nil
    session[:ooc_scan_search]=nil
    session[:ooc_missed_scan_search]=nil
    session[:ooc_release_scan_search]=nil
    session[:ooc_deviation_search]=nil
    session[:ooc_copy_groups_search]=nil
    session[:task_status]=nil
  end
  # value for the selected group type in OOC filters
  # selected value is passed as an altertive if the ooc_group_type
  # is nil
  def session_group_type(selected="")
    session[:ooc_group_type] ||= selected
  end
  helper_method :session_group_type

  # generate lookup lists for group_name and scan_type
  # used by all out of cycle controllers.
  def group_scan_lists
    (org_l1_id,org_id) = current_org_id.split(',')
    if controller_name=="assets"
      @group_name_list_all = OocGroup.find_all_by_ooc_group_type(params[:ooc_group_type] ||= session_group_type,:order=>:ooc_group_name,
        :conditions=>["org_l1_id=? and org_id=?",org_l1_id,org_id])
    else
      #$stderr.puts "scan_type #{params[:ooc_scan_type]} | #{ooc_scan_type} "
      scan_type = params[:ooc_scan_type] ||= ooc_scan_type
      unless (scan_type.blank? or scan_type=='choose' or scan_type=='--------------')
        scan_type = OocScanType.find(scan_type)
        @ooc_group_type = scan_type.ooc_group_type
        @group_name_list = OocGroup.find_all_by_ooc_group_type(@ooc_group_type,
          :conditions=>["org_l1_id=? and org_id=? and ooc_group_status=? ",org_l1_id,org_id,'active'],:order=>:ooc_group_name)
        #@scan_type_list = OocScanType.find_all_by_ooc_group_type(params[:ooc_group_type] ||= session_group_type,
        #:order=>:ooc_scan_type)
      end
    end
    render :layout => false
  end
  ##########
  protected
  ##########


  def not_authorized(exception)
    render :template => "unauthorized", :status => :Forbidden
  end
  
  def not_authenticated(exception)
    render :template => "unauthenticated", :status => :Forbidden
  end

  private

  #get current org
  def current_org
    Org.find(current_org_id) if current_org_id
  end
 
  # check authorization for edit/create actions
  # admin role can view and edit everything
  # all roles can view everything
  def check_authorization
    admin = current_user.is_user_in_role?('Admin')
    account_focal = current_user.is_user_in_role_for_org("Account Focal", current_org_id)
    deviation_sme = current_user.is_user_in_role_for_org("Deviation SME", current_org_id)

    if admin
      return false#edit access granted    
      elsif AppConfig.read_only_flag=='y' and controller_path.include?("out_of_cycle") and (controller_name=='deviations'  or controller_name=='offline_suppressions')
      #system is in read-only mode for HC cycle Pages, and Both offline suppressions pages
  RAILS_DEFAULT_LOGGER.debug "ApplicationController::check_authorization System in READ ONLY Mode-Test 1"
      return true
    elsif AppConfig.read_only_flag=='y' and !controller_path.include?("out_of_cycle")
      #system is in read-only mode for all HC cycle Pages
  RAILS_DEFAULT_LOGGER.debug "ApplicationController::check_authorization System in READ ONLY Mode-Test 2"
         return true
    elsif AppConfig.ooc_read_only_flag=='y' and controller_path.include?("out_of_cycle")
      #system is in read-only mode for OOC Pages.
      return true
    elsif account_focal
 RAILS_DEFAULT_LOGGER.debug "ApplicationController::check_authorization  account_focal EDIT ACCESS Granted return false"
      return false #edit access granted
    elsif (controller_name=="deviations" or controller_name=="suppressions" or
          controller_name=="validation_groups")  and deviation_sme
 RAILS_DEFAULT_LOGGER.debug "ApplicationController::check_authorization EDIT ACCESS Granted Returning FALSE"
      return false #edit access granted
    else
      return true
    end
  end
  
end

  
