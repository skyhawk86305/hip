class Admin::RolesController < ApplicationController
  require_role 'Admin'

  def index
    @show_element="admin"
    @roles = Role.paginate( :order=>"role_name",:page=>params[:page],:per_page=>10)
    @orgs = Org.service_hip.paginate :order=>:org_name,:page=>params[:page],:per_page=>10
  end

  def new
    @show_element="admin"
    @role = Role.new
  end

  def search
    @orgs = Org.service_hip.paginate :conditions=>["lower(org_name) like ?","%#{params[:org_name].downcase.strip}%"],
      :order=>:org_name,:page=>params[:page],:per_page=>params[:per_page]
    respond_to do |format|
      format.html
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"org_result")
        end
      }
    end
  end
  #  def show
  #    @role = Role.find(parmas[:id])
  #  end

  def edit
    @show_element="admin"
    @role = Role.find_by_role_name(params[:id])
  end

  def create
    @role = Role.new(params[:role])
    @role.lu_userid = current_user.userid
    respond_to do |format|
      if @role.save
        flash[:notice] = 'Role was successfully created.'
        format.html { redirect_to(:action=>"index")}
        format.xml  { render :xml => @role, :status => :created, :location => @role }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @role = Role.find_by_role_name(params[:id])
    @role.lu_userid = current_user.userid
    respond_to do |format|
      if @role.update_attributes(params[:role])
        flash[:notice] = 'Role was successfully updated.'
        format.html { redirect_to(:action=>"index") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @role = Role.find_by_role_name(params[:id])
    @role.destroy
    respond_to do |format|
      format.html { redirect_to(admin_roles_path) }
      format.xml  { head :ok }
    end
  end

end
