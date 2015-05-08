class HcGroupsController < ApplicationController
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search]

  def index
    @show_element="incycle"
    @group = HcGroup.new
  end

  # lookup from index page.
  def search
    session[:per_page]=params[:per_page]
    page_number = (params[:page] || 1).to_i
    per_page = params[:per_page].to_i  
    @groups_search = WillPaginate::Collection.create(page_number, per_page) do |pager|
      result = HcGroupSearch.search(:org_id => current_org_id, :hc_group_name => params[:hc_group][:group_name_search], :sort_direction => params[:sort].downcase)
      row_from = (page_number - 1) * per_page
      row_to = (row_from + per_page) - 1
      pager.replace(result[row_from..row_to])
      pager.total_entries = result.size
    end   
  end

  def edit
    @show_element="incycle"
    @group = HcGroup.find(params[:id])
  end

  
  def create
    # Remove leading, trailing, and multiple blanks from group name
    params[:hc_group][:group_name] = params[:hc_group][:group_name].strip.gsub(/\s{2,}/, ' ')
    
    @group = HcGroup.new(params[:hc_group])
    # setting defualts
    @group.is_current="n"
    @group.lu_userid=current_user.userid
    org = Org.find(current_org_id)
    @group.org_l1_id=org.org_l1_id
    @group.org_id=org.org_id
    
    respond_to do |format|
      begin
        @group.save!
        flash[:notice] = 'Health Check Group was successfully created.'
        format.html { redirect_to(:action=>"index")}
      rescue ActiveRecord::StatementInvalid => error
        if error.to_s =~ /duplicate key/
          flash[:error] = "Health Check Group was not created! Error: Group Name #{params[:hc_group][:group_name]} exists."
        else
          flash[:error] = "Health Check Group was not created! Error: #{error}"
        end
      rescue ActiveRecord::RecordInvalid# =>error
        flash[:error] = "Health Check Group Name can not be blank."
          
      end
      format.html { redirect_to :action => "index" }
    end
  end

  def update
    # Remove leading, trailing, and multiple blanks from group name
    params[:hc_group][:group_name] = params[:hc_group][:group_name].strip.gsub(/\s{2,}/, ' ')
    
    @group = HcGroup.find(params[:id])
    @group.lu_userid=current_user.userid
    respond_to do |format|
      if @group.update_attributes(params[:hc_group])
        flash[:notice] = 'Health Check Group was successfully updated.'
        format.html { redirect_to(:action=>"index") }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @group = HcGroup.find(params[:id])
    @group.destroy
    respond_to do |format|
      format.html { redirect_to(:action=>"index") }
    end
  end
end