class ScansController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:get]

  def index
    @show_element="incycle"
    @scan_search = ScanSearch.new
  end

  def search
    session[:hc_group_id]=params[:scan_search][:hc_group_id]
    session[:per_page]=params[:scan_search][:per_page]
    @asset_scans = ScanSearch.search(params[:scan_search]).paginate :page=>params[:page],:per_page=>params[:scan_search][:per_page]
    # build select list to mark scans
    if @asset_scans.size > 0
      labled_list = labled_scan_list(@asset_scans)
      scans= ScanSearch.scan_count(@asset_scans,params[:scan_search], true)
      @scanlist = scanlist(scans, labled_list)
    end


    # put params in to session for use later.
    session[:scan_search]=params[:scan_search]
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
    unless label_option =="Select Option"
      if label_option=='remove_label'
        destroy
      end
      if label_option=='all'
        apply_update_all
      end

      if label_option=='selected'
        apply_update(params[:scans][:scan].values)
      end

      if label_option=="ready"
        apply_label(params[:scans][:scan].values)
      end
      if label_option=='unlabel_all'
        unlabel_all()
      end
      if label_option=="ready_all"
        apply_label_all
      end

    end

    SwareBase.uncached do
      @asset_scans = ScanSearch.search(session[:scan_search]).paginate :page=>params[:page],:per_page=>session[:scan_search][:per_page]
    
      if @asset_scans.size > 0
        labled_list = labled_scan_list(@asset_scans)
        scans= ScanSearch.scan_count(@asset_scans, session[:scan_search], true)
        @scanlist = scanlist(scans, labled_list)
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

  #remove the label
  def destroy
    scan = Scan.find params[:scan_id]
    scan.destroy
    @asset_scans = ScanSearch.search(session[:scan_search]).paginate :page=>params[:page],:per_page=>session[:scan_search][:per_page]
    if @asset_scans.size > 0
      labled_list = labled_scan_list(@asset_scans)
      scans= ScanSearch.scan_count(@asset_scans, session[:scan_search], true)
      @scanlist = scanlist(scans, labled_list)
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
  private

  def labled_scan_list(asset_scans)
    asset_scans.map {|as| as.scan_id if as.scan_id}
  end

  # build list of scans for labeling.
  def scanlist(asset_scans, labled_scan_list = [])
    scanlist={:labled => [], :unlabled => []}
    asset_scans.each do |as|
      # create the select array with the first option
      scanlist[:unlabled][as.asset_id]=[["Select Scan",0]] unless scanlist[:unlabled][as.asset_id]
      # check if the scan is already labeled or released as a HC Cycle Scan
      scan = Scan.find(:first,:conditions=>{:scan_id=>as.scan_id}) #unless as.scan_id.nil?
      if !scan.nil?
        # create the labeled scan for display
        scanlist[:labled][as.scan_id] = "#{as.count}|#{as.scan_start_timestamp}|#{as.manager_name}"
      else
        # Check if scan is already labeled or released as an OOC scan
        scan = OocScan.find(:first, :conditions => {:scan_id => as.scan_id})
        if scan.nil?
          # if the scan is not labeled, or released, put it in the unlabeled list
          scanlist[:unlabled][as.asset_id].push(["#{as.count}|#{as.scan_start_timestamp}|#{as.manager_name}",as.scan_id])
        end
      end
    end
    #puts scanlist
    scanlist
  end

  def apply_update(scan_array)
    scans_to_label = []
    scan_array.each do |scan|
      if scan.include?("scan_id") # if there is no drop down, scan_id is not included.
        scan_id = scan['scan_id']
        if scan_id.to_s !="0"
          scans_to_label << scan_id
        end
      end
    end
    period = HipPeriod.current_period
    Scan.label_scans(scans_to_label, :lu_userid => current_user.userid)
  end

  # Label the lastest can for all scans in the filter
  # but they do not have publish_ready_timestamp
  # set.
  def apply_update_all
    # all scans from filter
    scans_to_label = []
    all_scans = ScanSearch.search(session[:scan_search])
    all_scans.each do |scan|
      if scan.system_scan_status =~ /^Available/
        scans_to_label << ScanSearch.latest_scan(scan.asset_id,current_org_id).first[:scan_id]
      end
    end
    Scan.label_scans(scans_to_label, :lu_userid => current_user.userid)
  end

  # update selected scans on result
  def apply_label(scans_array)
    scans_array.each do |scan|
      if scan['ready_to_publish']=='y'
        existing_scan = Scan.find(scan['scan_id'])
        if ! existing_scan.publish_ready_timestamp?
          existing_scan.publish_ready_timestamp=Time.now.utc
          existing_scan.publish_ready_userid=current_user.userid
          existing_scan.save!
        end
      end
    end
  end

  # update all scans from filter
  def apply_label_all
    all_scans = ScanSearch.search(session[:scan_search])
    all_scans.each do |scan|
      existing_scan = Scan.find(scan['scan_id'])
      if ! existing_scan.publish_ready_timestamp?
        existing_scan.publish_ready_timestamp=Time.now.utc
        existing_scan.publish_ready_userid=current_user.userid
        existing_scan.save!
      end
    end
  end

  # remove all labeled
  def unlabel_all
    scans = ScanSearch.search(session[:scan_search])
    scan_ids = scans.find_all{|s| !s.scan_id.blank? }.map{|s| s.scan_id}
    Scan.delete_all("publish_ready_timestamp is null and scan_id in (#{scan_ids.join(",")})")
  end
end
