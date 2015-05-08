class PublishScansController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:get]

  def index
    @show_element="incycle"
    @publish_scan_search = PublishScanSearch.new
  end

  def search
    session[:hc_group_id]=params[:publish_scan_search][:hc_group_id]
    session[:per_page]=params[:publish_scan_search][:per_page]
    asset_scans = PublishScanSearch.search(params[:publish_scan_search])
    total_counts(asset_scans)
    #@total_released= asset_scans.sum{|a| x=0; if a.publish_ready_timestamp!=nil; x+=1 end}
    @asset_scans = asset_scans.paginate :page=>params[:page],:per_page=>params[:publish_scan_search][:per_page]
    # put params in to session for use later.
    session[:publish_scan_search]=params[:publish_scan_search]
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end


  def update
    label_option = params[:scans][:option]
      
    case label_option
    when "selected"
      apply_label(params[:scans][:scan].values)
    when "all"
      apply_label(PublishScanSearch.search(session[:publish_scan_search]))
    end
    SwareBase.uncached do
      @asset_scans = PublishScanSearch.search(session[:publish_scan_search]).paginate \
        :page=>params[:page],:per_page=>session[:publish_scan_search][:per_page]
    end
    total_counts(@asset_scans)
    
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end

  private

  def labeled_scan_list(asset_scans)
    asset_scans.map {|as| as.scan_id if as.scan_id}
  end

  # build list of scans for labeling.
  def scanlist(asset_scans, labled_scan_list = [])
    scanlist={:labled => [], :unlabled => []}
    # fmt="%Y-%m-%d %H:%M:%S.0"
    asset_scans.each do |as|
      # id="#{as.asset_id.to_s},#{as.tool_id.to_s},#{as.scan_stop_timestamp.strftime(fmt)}"
      scanlist[:unlabled][as.asset_id]=[["Select Scan",0]] unless scanlist[:unlabled][as.asset_id]
      if labled_scan_list.index(as.scan_id)
        scanlist[:labled][as.scan_id] = "#{as.count}|#{as.scan_start_timestamp}"
      else
        scanlist[:unlabled][as.asset_id].push(["#{as.count}|#{as.scan_start_timestamp}",as.scan_id])
      end
    end
    #puts scanlist
    scanlist
  end

  # update selected scans on result
  def apply_label(scans_array)
    # only process labeled scans that are not released
    scans= scans_array.find_all{|s| s['scan_id'].to_i !=0 && s['publish_ready_timestamp'].nil?}
    # only pass the scan_id to createall
    scans.map!{|s| s['scan_id']}
    period_id = SwareBase.current_period_id
    unless scans.nil?
      Scan.transaction do
        Scan.create_all!(scans,current_user.userid,period_id)
      end
    end
  end

  def total_counts(asset_scans)
    @total_clean = asset_scans.sum{|a| a.clean.to_i}
    @total_validated = asset_scans.sum{|a| a.deviation_count.to_i - a.suppressed.to_i}
    @total_suppressed = asset_scans.sum{|a| a.suppressed.to_i}
    @total_released=0
    asset_scans.each do |a|
      if a.publish_ready_timestamp!=nil
        @total_released+=1
      end
    end
  end
end
