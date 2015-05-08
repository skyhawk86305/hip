class SuppressionsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search]

  def index
    @show_element= "suppress"
    @exception_search = ExceptionSearch.new
  end

  def search
    session[:per_page]=params[:exception_search][:per_page]
    @show_element="suppress"
    @exceptions = ExceptionSearch.exceptions(params[:exception_search],params[:page])
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end
  
  def new
    @show_element="suppress"
    (org_l1_id, org_id) = current_org_id.split(',')
    @ex = Suppression.new({:org_l1_id => org_l1_id, :org_id => org_id})
  end

  def edit
    @show_element="suppress"
    @@org = Org.find(current_org_id)
    @ex = Suppression.find params[:id]

  end

  def create
    @org = Org.find(current_org_id)
    
    # Remove leading, trailing, and multiple blanks from suppression name
    params[:suppression][:suppress_name] = params[:suppression][:suppress_name].strip.gsub(/\s{2,}/, ' ')
    
    (org_l1_id, org_id) = current_org_id.split(',')
    @ex = Suppression.new(params[:suppression].merge({:org_l1_id => org_l1_id, :org_id => org_id}))
    begin
      if ! params[:suppression][:system_name].blank? and params[:suppression][:automatic_suppress_flag]=='y'
        asset = @org.assets.find(:first, :conditions=>["host_name = ?",params[:suppression][:system_name]])

        if asset.nil?
          @ex.errors.add :system_name, "Unable to find System Name: #{params[:suppression][:system_name]}"

          #raise "Unable to find System Name: #{params[:suppression][:system_name]}"
        end
        @ex.asset_id=asset.tool_asset_id
      end
     
      if !params[:suppression][:vuln_title].blank? and params[:suppression][:automatic_suppress_flag]=='y'
        vuln = Vuln.find_by_title(params[:suppression][:vuln_title])

        if vuln.nil?
          @ex.errors.add :vuln_title, "Unable to find Deviation Type: #{params[:suppression][:vuln_title]}"
        end
        @ex.vuln_id = vuln.vuln_id
      end

      @ex.lu_userid=current_user.userid
      @ex.save!
      unless params[:suppression][:hc_group_ids].blank?
        apply_update(@ex.suppress_id,params[:suppression][:hc_group_ids])
      end
      respond_to do |format|
        flash[:notice] = "Suppression was created successfully!"
        format.html {redirect_to :action=>"index"}
      end
    rescue Exception => error
      respond_to do |format|
        # flash[:error] = error.message
        flash[:error] = "Suppression was not created!"
        format.html  { render :action => "new" }
      end
    end
  end

  def update
    @org = Org.find(current_org_id)
    @ex = Suppression.find(params[:id])

    begin
      if !params[:suppression][:system_name].blank? and params[:suppression][:automatic_suppress_flag]=='y'
        asset = @org.assets.find(:first, :conditions=>["host_name = ?",params[:suppression][:system_name]])

        if asset.nil?
          raise "Unable to find System Name: #{params[:suppression][:system_name]}"
        end
        @ex.asset_id=asset.tool_asset_id
      end
      if !params[:suppression][:vuln_title].blank? and params[:suppression][:automatic_suppress_flag]=='y'
        vuln = Vuln.find_by_title(params[:suppression][:vuln_title])
        if vuln.nil?
          raise "Unable to find Deviation Type: #{params[:suppression][:vuln_title]}"
        end
        @ex.vuln_id = vuln.vuln_id
      end

      @ex.lu_userid=current_user.userid      
      params[:suppression].delete(:start_timestamp) # insure that the start_timestamp doen't change
      # Remove leading, trailing, and multiple blanks from suppression name
      params[:suppression][:suppress_name] = params[:suppression][:suppress_name].strip.gsub(/\s{2,}/, ' ')
      
      @ex.update_attributes!(params[:suppression])
      unless params[:suppression][:hc_group_ids].blank?
        apply_update(@ex.suppress_id,params[:suppression][:hc_group_ids])
      end
      respond_to do |format|
        flash[:notice] = "Suppression was updated successfully!"
        format.html {redirect_to :action=>"index"}
      end
    rescue Exception => error
      respond_to do |format|
        #flash[:error] = error.message
        flash[:error] = "Suppression was not updated!"
        format.html  { render :action => "edit" }
      end
    end
  end

  def destroy
    @exception = Suppression.find params[:id]
    SuppressGroup.delete_all(:suppress_id=>params[:id])
    SuppressFinding.delete_all(:suppress_id =>params[:id])
    respond_to do |format|
      if @exception.destroy
        flash[:notice]="Exception sucessfully deleted!"
        format.html {redirect_to :action=>"index"}
      else
        flash[:error]="Exception could not be deleted"
        format.html {redirect_to :action=>"index"}
      end
    end
  end

  private

  ###
  # find the SuppressGroup record
  # and delete it if it already exists.  if it is new
  # create a new asset_group record
  def apply_update(suppress_id, hc_group_ids)
    sg =SuppressGroup.find_by_suppress_id(suppress_id)
    # create new asset_group recored
    if sg.blank?
      new_suppress_group(suppress_id,hc_group_ids)
    else
      SuppressGroup.delete_all(:suppress_id=>suppress_id)
      new_suppress_group(suppress_id,hc_group_ids)
    end
  end

  

  ###
  # simply create a new SuppessGroup Records
  #
  def new_suppress_group(suppress_id,hc_group_ids)
    hc_group_ids.each do |h|
      sg=SuppressGroup.new(:suppress_id=>suppress_id,:hc_group_id=>h,:lu_userid=>current_user.userid)
      sg.save!
    end
  end

end
