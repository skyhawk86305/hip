class OutOfCycle::MissedScansController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:edit,:new,:group_scan_lists]
  
  #### missed scan methods
  def index
    @show_element="outofcycle"
  end

  def search
    session[:per_page]=params[:per_page]
    session[:ooc_group_type] = params[:ooc_group_type]
    session[:ooc_group_id] = params[:ooc_group_id]
    session[:ooc_scan_type] = params[:ooc_scan_type]
    session[:ooc_missed_scan_search]=search_params(params)
    @missed_scans = OocMissedScanSearch.search(session[:ooc_missed_scan_search]).paginate :page => params[:page],
      :per_page => session[:ooc_missed_scan_search][:per_page]
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end

  def update
    label_option = params[:missed_scans_reason][:option]
    reason_id = params[:missed_scans_reason][:reason_id]
    scan_type = params[:missed_scans_reason][:ooc_scan_type]
    case label_option
    when "selected"
     
      apply_reason(params[:missed_scans_reason][:reason].values)
    when "all"
      apply_reason(OocMissedScanSearch.search(session[:ooc_missed_scan_search]))
    when "remove"
      remove_missed_scan(params[:missed_scans_reason][:reason].values)
    when "remove_all"
      remove_missed_scan(OocMissedScanSearch.search(session[:ooc_missed_scan_search]))
    end
    SwareBase.uncached() do
      @missed_scans = OocMissedScanSearch.search(session[:ooc_missed_scan_search]).paginate(:page=>params[:page],:per_page=>session[:ooc_missed_scan_search][:per_page])
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
    reason_id = params[:missed_scans_reason][:reason_id]
    scan_type = params[:missed_scans_reason][:ooc_scan_type]
    ooc_group_id = params[:missed_scans_reason][:ooc_group_id]
    missed = []
    asset_array.each do |asset|
      unless asset['asset_id'].blank?
        OocMissedScan.transaction do
          ms = OocMissedScan.find(:first,:conditions=>["asset_id=? and ooc_group_id=?",asset['asset_id'].to_i,asset['ooc_group_id'].to_i])
          if !ms.nil? and reason_id!=ms.missed_scan_reason_id
            ms.destroy
            ms=nil
          end
          if ms.nil?
            missed << {
              :ooc_group_id => ooc_group_id,
              :asset_id=>asset['asset_id'],
              :missed_scan_reason_id=>reason_id,
              :ooc_scan_type=>scan_type,
              :lu_userid=>current_user.userid,
            }
          end
        
        end
      end
    end
    OocMissedScan.create_all! missed
  end

  def remove_missed_scan(assets)
    scan_type = params[:missed_scans_reason][:ooc_scan_type]
    ooc_group_id = params[:missed_scans_reason][:ooc_group_id]
    asset_ids= assets.find_all{|m| !m['asset_id'].blank?}.map{|m| m['asset_id']}
    OocMissedScan.delete_all("ooc_scan_type=#{SwareBase.quote_value(scan_type)} and ooc_group_id=#{ooc_group_id} and asset_id in (#{asset_ids.join(',')})")
  end
  def search_params(params)
    {:per_page => params[:per_page],
      :org_id=>params[:org_id],
      :ooc_group_id=>params[:ooc_group_id],
      :ooc_group_type=>params[:ooc_group_type],
      :ooc_scan_type=>params[:ooc_scan_type],
      :host_name=>params[:host_name],
      :ip_address=>params[:ip_address],
      :os_product=>params[:os_product],
      :system_status=>params[:system_status],
      :reason_id => params[:reason_id]

    }
  end
end
