class OutOfCycle::ReleaseScansController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:get,:group_scan_lists]

  def index
    @show_element="outofcycle"
  end

  def search
    session[:per_page]=params[:per_page]
    session[:ooc_group_type] = params[:ooc_group_type]
    session[:ooc_group_id] = params[:ooc_group_id]
    session[:ooc_scan_type] = params[:ooc_scan_type]
    session[:ooc_publish_scan_search]=search_params(params)
    asset_scans = OocReleaseScanSearch.search(session[:ooc_publish_scan_search])
    total_counts(asset_scans)
    @asset_scans = asset_scans.paginate :page=>params[:page],:per_page=>session[:ooc_publish_scan_search][:per_page]
 
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
      apply_label(OocReleaseScanSearch.search(session[:ooc_publish_scan_search]))
    end
    SwareBase.uncached do
    @asset_scans = OocReleaseScanSearch.search(session[:ooc_publish_scan_search]).paginate \
                  :page=>params[:page],:per_page=>session[:ooc_publish_scan_search][:per_page]
    end

    total_counts(@asset_scans)
    #@asset_scans = asset_scans
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end

  private

  # update selected scans on result
  def apply_label(scans_array)
    # only process labeled scans that are not released
    scans= scans_array.find_all{|s| s['scan_id'].to_i != 0 && s['publish_ready_timestamp'].nil?}
    # only pass the scan_id to createall
    scans.map!{|s| s['scan_id']}
      unless scans.nil?
        SwareBase.transaction do
          OocScan.create_all!(scans,current_user.userid)
        end
      end
  end

  def total_counts(asset_scans)
    @total_clean = asset_scans.sum{|a| a.clean.to_i}
    @total_validated = asset_scans.sum{|a| a.deviation_count.to_i - a.count_suppressed.to_i}
    @total_suppressed = asset_scans.sum{|a| a.count_suppressed.to_i}
    @total_released=0
    asset_scans.each do |a|
      if a.publish_ready_timestamp!=nil
        @total_released+=1
      end
    end
  end

  def search_params(params)
    {:per_page => params[:per_page],
      :org_id=>params[:org_id],
      :ooc_group_id=>params[:ooc_group_id],
      :ooc_scan_type=>params[:ooc_scan_type],
      :ooc_group_type=>params[:ooc_group_type],
      :host_name=>params[:host_name],
      :ip_address=>params[:ip_address],
      :os=>params[:os],
      :system_status=>params[:system_status],
      :publish_status => params[:publish_status],
      :val_status =>params[:val_status]
    }
  end
end
