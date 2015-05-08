class MissedScansController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:edit,:new]
  
  #### missed scan methods
  def index
    @show_element="incycle"
    @missed_scans_search = MissedScanSearch.new
  end

  def edit
    @show_element="incycle"
    @missed_scan = MissedScan.find params[:id]
    @asset = Asset.find_by_tool_asset_id(@missed_scan.asset_id)
  end

  def search
    session[:hc_group_id]=params[:missed_scan_search][:hc_group_id]
    session[:per_page]=params[:missed_scan_search][:per_page]
    session[:missed_scan_search]=params[:missed_scan_search]
    @missed_scans = MissedScanSearch.search(params[:missed_scan_search]).paginate :page => params[:page],
      :per_page => params[:missed_scan_search][:per_page]
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end

  def new
    @show_element="incycle"
    @missed_scan = MissedScan.new
    @asset = Asset.find_by_tool_asset_id(params[:asset_id])
  end

  def create

    @missed = MissedScan.new(params[:missed_scan])
    period = HipPeriod.current_period
    @missed.period_id=period.to_param
    @missed.lu_userid=current_user.userid
    respond_to do |format|
      if @missed.save!
        flash[:notice] = "Missed scan created!"
        format.html {redirect_to :action=>:index}
      else
        flash[:notice] = "Missed scan could not be created!"
        format.html {render :action=>:new}
      end
    end
  end

  def update
    label_option = params[:missed_scans_reason][:option]

    case label_option
    when "selected"
      apply_reason(params[:missed_scans_reason][:reason].values)
    when "all"
      apply_reason(MissedScanSearch.search(session[:missed_scan_search]))
    when "remove"
      remove_missed_scan(params[:missed_scans_reason][:reason].values)
    when "remove_all"
      remove_missed_scan(MissedScanSearch.search(session[:missed_scan_search]))
    end
    SwareBase.uncached do
      @missed_scans = MissedScanSearch.search(session[:missed_scan_search]).paginate(:page=>params[:page],:per_page=>session[:missed_scan_search][:per_page])
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end
  #  def update
  #    @missed = MissedScan.find params[:id]
  #    @missed.period_id=HipPeriod.current_period.to_param
  #    respond_to do |format|
  #      if @missed.update_attributes(params[:missed_scan])
  #        flash[:notice] = "Missed scan updated"
  #        format.html {redirect_to :action=>:index}
  #      else
  #        flash[:notice] = "Missed scan could not be updated!"
  #        format.html {render :action=>:edit}
  #      end
  #    end
  #  end

  def destroy
    @missed = MissedScan.find(params[:id])
    respond_to do |f|
      if @missed.destroy
        f.html {redirect_to :action=>:index}
      else
        f.html {render :action=>:edit}
      end
    end
  end

  private
  # update selected missing scans on result filter
  def apply_reason(asset_array)
    missed = []
    asset_array.each do |asset|
      unless asset['tool_asset_id'].blank?
        
        MissedScan.transaction do
          ms = MissedScan.find_by_period_id_and_asset_id(SwareBase.current_period_id,asset['tool_asset_id'])
          if !ms.nil? and params[:missed_scans_reason][:reason_id]!=ms.missed_scan_reason_id
            ms.destroy
            ms=nil
          end
          if ms.nil? #and !asset['reason_id'].blank?
            missed << {
              :period_id=>SwareBase.current_period_id,
              :asset_id=>asset['tool_asset_id'],
              :missed_scan_reason_id=>params[:missed_scans_reason][:reason_id],
              :lu_userid=>current_user.userid
            }
            
          end
          
        end
      end
    end
    MissedScan.create_all!(missed)
  end

  def remove_missed_scan(assets)
    asset_ids= assets.find_all{|m| !m['tool_asset_id'].blank?}.map{|m| m['tool_asset_id']}
    MissedScan.delete_all("period_id=#{SwareBase.current_period_id} and asset_id in (#{asset_ids.join(',')})")
  end
  
end
