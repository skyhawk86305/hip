class DashboardController < ApplicationController

  before_filter :select_org
  before_filter :has_current_org_id
  
  def index
    @show_element="incycle"
    @org = Org.find(current_org_id)
    @period = SwareBase.current_period
    account_dashboard_results = ReportHcCycleSearch.search({'org_id' => @org.id})
    @unassigned_assets_count = nil
    @current_groups_total = nil
    @not_current_groups_total = nil
    @current_totals_by_group = {}
    @not_current_totals_by_group = {}
    account_dashboard_results.each do |row|
      if row[:group_name].nil? && row[:is_current].nil?
        @unassigend_assets_count = row
      elsif row[:group_name].nil? && row[:is_current] == 'y'
        @current_groups_total = row
      elsif row[:group_name].nil? && row[:is_current] == 'n'
        @not_current_groups_total = row
      elsif row[:is_current] == 'y'
        @current_totals_by_group[row[:group_name]] = row
      else
        @not_current_totals_by_group[row[:group_name]] = row
      end
    end
  end


  #private
  #def get_scans(org_id)
  #  ScanSearch.search({
  #      "hc_group_id"=>"all",
  #      "org_id"=>org_id,
  #      "scan_tool_id"=>"all",
  #      "scan_type"=>"all",
  #      "start_date"=>"",
  #      "end_date"=>""
  #    })
  #end
  #
  #def get_released_scans(org_id)
  #
  #  PublishScanSearch.search({
  #      "hc_group_id"=>"all",
  #      "org_id"=>org_id,
  #      "val_status"=>"all",
  #      "scan_type"=>"all",
  #      "os"=>"all",
  #      "publish_status"=>"all"
  #    })
  #end

end
