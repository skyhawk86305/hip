class OutOfCycle::ScansController < ApplicationController

  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:group_scan_lists]

  def index
    @show_element="outofcycle" 
  end

  def search
    session[:per_page]=params[:per_page]
    session[:ooc_scan_search] = search_params(params)
    session[:ooc_group_type] = params[:ooc_group_type]
    session[:ooc_group_id] = params[:ooc_group_id]
    session[:ooc_scan_type] = params[:ooc_scan_type]
    # do some error checking and send the error message to the user.
    msg=nil
    unless params[:start_date].blank?
      start_date = Date.strptime(params[:start_date],"%m/%d/%Y")
      if (Date.today - 31.days) > start_date
        msg="The Date Range From date must not be more then 31 days in the past."
      end
    end
    unless params[:end_date].blank?
      end_date = Date.strptime(params[:end_date],"%m/%d/%Y")
      if  end_date > Date.today
        msg = "The Date Range To date must not be in the future."
      end
    end
    if msg
      respond_to do |format|
        format.js {
          render :update do |page|
            page.call 'alert',msg
          end
        }
        format.html {render :action=>:index}

      end
      return
    end
    @scans = OocScanSearch.search(session[:ooc_scan_search]).paginate :page=>params[:page],:per_page=>session[:ooc_scan_search][:per_page]
    # build select list to mark scans
    if @scans.size > 0
      assets = @scans.map {|as| as.asset_id}
      scans_count= OocScanSearch.scan_count(:assets=>assets,
        :org_id => current_org_id,
        :start_date => session[:ooc_scan_search][:start_date],
        :end_date => session[:ooc_scan_search][:end_date],
        :ooc_scan_type => params[:ooc_scan_type],
        :ooc_group_id => params[:ooc_group_id]
        )
      @scanlist = scanlist(scans_count)
    end

    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end
  
  def update
    label_option = params[:option]
    unless label_option =="Select Option"

      if label_option=='remove_label'
        destroy
      end
      if label_option=='unlabel_all'
        unlabel_all
      end
      if label_option=='all'
        apply_update_all(params[:scan_type])
      end

      if label_option=='selected'
        apply_update(params[:scans][:scan].values,params[:scan_type])
      end

    end

    SwareBase.uncached do
    @scans = OocScanSearch.search(session[:ooc_scan_search]).paginate :page=>params[:page],:per_page=>session[:ooc_scan_search][:per_page]
      if @scans.size > 0
        assets = @scans.map {|as| as.asset_id}
        scans_count= OocScanSearch.scan_count(:assets=>assets,
          :org_id => current_org_id,
          :start_date => session[:ooc_scan_search][:start_date],
          :end_date => session[:ooc_scan_search][:end_date],
          :ooc_scan_type => params[:ooc_scan_type],
          :ooc_group_id => session[:ooc_scan_search][:ooc_group_id]
          )
        @scanlist = scanlist(scans_count)
      end
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end

  def destroy
    scan = OocScan.find_by_scan_id(params[:scan_id])
    scan.destroy

    @scans = OocScanSearch.search(session[:ooc_scan_search]).
                           paginate :page=>params[:page],
                                    :per_page=>session[:ooc_scan_search][:per_page]
    if @scans.size > 0
      assets = @scans.map {|as| as.asset_id}
      scans_count = OocScanSearch.scan_count(
        :assets=>assets,
        :org_id => current_org_id,
        :start_date => session[:ooc_scan_search][:start_date],
        :end_date => session[:ooc_scan_search][:end_date],
        :ooc_scan_type => params[:ooc_scan_type],
        :ooc_group_id => session[:ooc_scan_search][:ooc_group_id]
      )
      @scanlist = scanlist(scans_count)
    end

    respond_to do |format|
      format.html { redirect_to( :action=>:search)}
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end
  
  ##########
  private
  ##########
  
  # build list of scans for labeling.
  def scanlist(asset_scans)
    scanlist={:labled => [], :unlabled => []}
    asset_scans.each do |as|
      # create the select array with the first option
      scanlist[:unlabled][as.asset_id]=[["Select Scan",0]] unless scanlist[:unlabled][as.asset_id]
      # check if the scan is already used
      if as.used == 'y'
        scanlist[:labled][as.scan_id] = "#{as.count}|#{Time.parse(as.scan_start_timestamp,"%Y-%m-%d %H:%M:%S.000000").strftime("%Y-%m-%d %H:%M:%S")}|#{as.manager_name}"
      else
        # if the scan is not labeled, or released, put it in the unlabeled list
        scanlist[:unlabled][as.asset_id].push(["#{as.count}|#{Time.parse(as.scan_start_timestamp,"%Y-%m-%d %H:%M:%S.000000").strftime("%Y-%m-%d %H:%M:%S")}|#{as.manager_name}",as.scan_id])
      end
    end
    scanlist
  end

  def apply_update(scan_array,scan_type)
    (org_l1_id,org_id)=current_org_id.split(',')
    scans_to_label = []
    scan_array.each do |scan|
      if scan.include?("scan_id") # if there is no drop down, scan_id is not included.
        scan_id = scan['scan_id'].to_i
        scans_to_label << scan_id unless scan_id == 0
      end
    end
    OocScan.label_scans(scans_to_label, ooc_group_id, ooc_scan_type, :lu_userid => current_user.userid)
  end

  # create a scan for all scans in the filter
  # but they do not have publish_ready_timestamp
  # set.
  def apply_update_all(scan_type)
    
    search_params = session[:ooc_scan_search].dup.update({:can_be_labeled => true})
    all_scans = OocScanSearch.search(search_params)
    
    # exit early if there is nothing to do
    return nil if all_scans.empty?
    
    # Get list of asset_id's
    asset_ids = all_scans.find_all {|s| s[:system_scan_status] == 'Available, none labeled'}.map {|s| s.asset_id}
    
    # Label all the assets with the latest available scan

    ooc_group_id = session[:ooc_scan_search][:ooc_group_id][0].to_s.to_i

RAILS_DEFAULT_LOGGER.debug "OutOfCycle::ScansController ooc_group_id is #{ooc_group_id}"

    scan_ids = OocScan.find_latest_scan(asset_ids, ooc_group_id)

    OocScan.label_scans(scan_ids, ooc_group_id, scan_type, :lu_userid => current_user.userid)
    return nil
  end

  # remove all labeled
  def unlabel_all
    scans = OocScanSearch.search(session[:ooc_scan_search])
    scan_ids = scans.find_all{|s| !s.scan_id.blank? }.map{|s| s.scan_id}
    OocScan.delete_all("publish_ready_timestamp is null and scan_id in (#{scan_ids.join(",")})")
  end
   
  def search_params(params)
    {:per_page => params[:per_page],
      :org_id=>params[:org_id],
      :ooc_group_id=>params[:ooc_group_id],
      :ooc_scan_type=>params[:ooc_scan_type],
      :ooc_group_type=>params[:ooc_group_type],
      :host_name=>params[:host_name],
      :ip_address=>params[:ip_address],
      :os_product=>params[:os_product],
      :hc_required=>params[:hc_required],
      :hc_sec_class=>params[:hc_sec_class],
      :system_status=>params[:system_status],
      :system_scan_status => params[:system_scan_status],
      :start_date => params[:start_date],
      :end_date => params[:end_date],
      :scan_tool_id => params[:scan_tool_id]

    }
  end
end



