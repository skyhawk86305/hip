class OutOfCycle::DashboardController < ApplicationController

  before_filter :select_org
  before_filter :has_current_org_id
  
  def index
    @show_element="outofcycle"
    Rails.logger.debug {"out_of_cycle/dashboard_controller.rb INDEX method called"}   
  end
  
  def search
    RAILS_DEFAULT_LOGGER.debug "OocReportDashboardSearch controller: params: #{params.inspect}"
    @show_element="outofcycle"
    @group_type = OocScanType.find(params[:ooc_scan_type]).ooc_group_type

    search_params={
         :org_id=>current_org_id,
         :ooc_scan_type=>params[:ooc_scan_type],
         :ooc_group_type=>@group_type}

    Rails.logger.debug { "SEARCH: search_params_copy: before test for hipresetcounts: #{search_params}" }
    (org_l1_id, org_id) = current_org_id.split(',')
    if params[:reset_counts] == 'y'
        Rails.logger.debug {"SEARCH: in reset section"}
        active_groups = OocGroup.find(:all, :conditions => {:org_l1_id => org_l1_id, :org_id => org_id,
          :ooc_group_type => @group_type, :ooc_group_status => 'active'})
        active_groups.each do |group|
          RAILS_DEFAULT_LOGGER.debug "processing group #{group.id}"
          remove_released_scans_from_dashboard(group.id, params[:ooc_scan_type], current_user)
          unlabel_unreleased_scans(group.id, params[:ooc_scan_type])
          unset_missing_scan_reason(group.id, params[:ooc_scan_type]) 
        end
    end

    account_dashboard_results = OocReportDashboardSearch.search(search_params)
    @unassigned_assets_count = nil
    @current_groups_total = nil
    @not_current_groups_total = nil
    @current_totals_by_group = {}
    @not_current_totals_by_group = {}
    account_dashboard_results.each do |row|
      if row[:ooc_group_name].nil? && row[:is_current].nil?
        @unassigend_assets_count = row
      elsif row[:ooc_group_name].nil? && row[:is_current] == 'active'
        @current_groups_total = row
      elsif row[:ooc_group_name].nil? && row[:is_current] == 'inactive'
        @not_current_groups_total = row
      elsif row[:is_current] == 'active'
        @current_totals_by_group[row[:ooc_group_name]] = row
      else
        @not_current_totals_by_group[row[:ooc_group_name]] = row
      end
    end

   respond_to do |format|
       format.js {
       render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
       }
   end

  #end search 
  end

  ##############
  protected
  ##############

  def remove_released_scans_from_dashboard(ooc_group_id, scan_type, current_user)
    userid = OocScan.truncate_userid(current_user.userid)
    OocScan.update_all(["appear_in_dashboard = 'n', lu_userid = ?, lu_timestamp = current_timestamp", current_user.userid],
      ["ooc_group_id = ? and ooc_scan_type = ? and \
        appear_in_dashboard = 'y' and publish_ready_timestamp is not null", ooc_group_id, scan_type])
  end

  def unlabel_unreleased_scans(ooc_group_id, scan_type)
    OocScan.delete_all(["ooc_group_id = ? and ooc_scan_type = ? and publish_ready_timestamp is null", ooc_group_id, scan_type])   
  end

  def unset_missing_scan_reason(ooc_group_id, scan_type)
    OocMissedScan.delete_all(["ooc_group_id = ? and ooc_scan_type = ?", ooc_group_id, scan_type])
  end


#end class
end
