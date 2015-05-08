class Admin::RolesGroupsController < ApplicationController
  require_role 'Admin'

  auto_complete_for :roles_group, :blue_groups_name, 
    :select=> "distinct blue_groups_name",
    :limit=>20, :order => 'blue_groups_name ASC'
  
  def index
    @show_element="admin"

    unless params[:org_name].blank?
      org_name_conditions="and lower(org.org_name) like '%#{params[:org_name].downcase}%'"
    end
    @rolesgroups = RolesGroup.paginate(:conditions=>"role_name='#{params[:role_name]}' #{org_name_conditions}",
      :page=>params[:page],:per_page=>params[:per_page]
      #      ,
      #      :joins=>"LEFT JOIN dim_comm_org_v as org on org.org_id=hip_roles_bluegroup_v.org_id and org.org_l1_id=hip_roles_bluegroup_v.org_l1_id",
      #      :order=>"#{params[:order]||="org.org_name"} #{params[:sort]||="ASC"}"
    )
    @role = Role.find_by_role_name(params[:role_name])
  end
  # for new non-account related groups
  def new
    @show_element="admin"
    @action="create2"
    @rolesgroup = RolesGroup.new
    # set role_name for  role select list
    @rolesgroup.role_name = params[:role_name]
    @role =   Role.find_by_role_name(params[:role_name])
  end
  # for Account level roles
  def edit
    @show_element="admin"
    (l1id, id) = params[:id].split(',')
    @org = Org.find(params[:id])
    @rolesgroups = @org.roles_groups.all(:order=>:blue_groups_name)
  
    @rolesgroups.each do |group|
      @org.roles_groups.build
    end
    #@rolesgroup = RolesGroup.new
  end
  # for editing non-account related groups
  def edit2
    @show_element="admin"
    @action="update2"
    @rolesgroup = RolesGroup.find(params[:id])
    @role =   Role.find_by_role_name(@rolesgroup.role_name)
  end
  # for Account level roles
  def update
    @show_element="admin"
    (l1id,id) = params[:org_id].split(',')
    @org = Org.find([l1id,id])
    @rolesgroups = @org.roles_groups.all(:order=>:blue_groups_name)
       
    respond_to do |format|
      if @org.update_attributes(params[:org])
        flash[:notice] = 'Roles Groups was successfully updated.'
        format.html{redirect_to(:action=>"edit",:id=>@org )}
      else
        flash[:notice] ="There was a problem updating this record."
        format.html{ render :action => "edit" }
      end
    end
    
  end

  # for Account level roles
  def create
    @rolesgroup = RolesGroup.new(params[:roles_group])
    @rolesgroup.lu_userid=current_user.userid
    (l1id,id) = params[:org_id].split(',')
    org = Org.find([l1id,id])
    @rolesgroup.org_id=id
    @rolesgroup.org_l1_id=l1id

    respond_to do |format|
      if @rolesgroup.save
        flash[:notice] = 'Roles Group was successfully updated.'
        format.html {redirect_to :action=>:edit,:id=>org }
        format.xml  { head :ok }
      else
        @org = org
        @rolesgroups = @org.roles_groups.all
        flash[:notice] ="There was a problem updating this record."
        format.html { render :action => "edit"}
        format.xml  { render :xml => @rolesgroup.errors, :status => :unprocessable_entity }
      end
    end
  end
  # for editing non-account related groups
  def create2
    @rolesgroup = RolesGroup.new(params[:roles_group])
    @rolesgroup.lu_userid=current_user.userid
    @role = Role.find(@rolesgroup.role_name)
    if @role.has_associated_org.downcase=="y"
      org = Org.find(params[:roles_group][:pk_org_id])
      @rolesgroup.org=org
    end
    respond_to do |format|
      if @rolesgroup.save
        flash[:notice] = 'Roles Group was successfully created.'
        format.html { redirect_to(:action=>"index",:role_name=>@rolesgroup.role_name) }
        format.xml  { render :xml => @rolesgroup, :status => :created, :location => @rolesgroup }
      else
        @action="create2"
        flash[:notice] ="There was a problem creating this record."
        format.html { render :action => "new"}
        format.xml  { render :xml => @rolesgroup.errors, :status => :unprocessable_entity }
      end
    end
  end
  # for editing non-account related groups
  def update2
    @rolesgroup = RolesGroup.find(params[:id])
    @rolesgroup.lu_userid=current_user.userid
    @role = Role.find(@rolesgroup.role_name)
    if @role.has_associated_org.downcase=="y"
      org = Org.find(params[:roles_group][:pk_org_id])
      @rolesgroup.org=org
    end

    respond_to do |format|
      if @rolesgroup.update_attributes(params[:roles_group])
        flash[:notice] = 'Roles Group was successfully updated.'
        format.html { redirect_to(:action=>"index",:role_name=>@rolesgroup.role_name) }
        format.xml  { head :ok }
      else
        @action="update2"
        flash[:notice] ="There was a problem updating this record."
        format.html { render :action => "edit" }
        format.xml  { render :xml => @rolesgroup.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @rolesgroup = RolesGroup.find(params[:id])
    org = Org.find([@rolesgroup.org_l1_id,@rolesgroup.org_id])
    @rolesgroup.destroy
    respond_to do |format|
      flash[:notice]= 'Role Group was deleted!'
      format.html { redirect_to(:action=>"edit",:id=>org) }
      format.xml  { head :ok }
    end
  end

  def account_members
    (l1id, id) = params[:id].split(',')
    org = Org.find(params[:id])
    rolesgroups = org.roles_groups.all(:select=>"distinct blue_groups_name",:order=>:blue_groups_name)
    @members = []
    group_search = LdapGroupSearch.new
    rolesgroups.each do |group|
      @members.concat(group_search.fetch_blue_group_members(group.blue_groups_name))
    end
    @members.sort!

    
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("account_members", :partial=>"account_members")
        end
      }
    end

  end

end
