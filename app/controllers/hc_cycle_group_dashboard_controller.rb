class HcCycleGroupDashboardController < ApplicationController

  before_filter :select_org
  before_filter :has_current_org_id

  def index
    @show_element="incycle"
    @period = HipPeriod.current_period.first
  end

  def search
    @period = SwareBase.current_period
    @group = HcGroup.find(:first, :conditions => {:hc_group_id => params[:hc_group_id]})
    @assets = get_scans(current_org_id, params[:hc_group_id])
    @scans = get_released_scans(current_org_id, params[:hc_group_id])

    @system_count = 0
    @is_current = @group.is_current == 'y' ? "Yes" : "No"
    @missing_no_reason = 0
    @available_none_labeled = 0
    @labeled_none_released = 0
    @released = 0
    @missing_with_reason = 0

    @scans_labeled_not_released = 0
    @unreleased_unvalidated_deviations = 0
    @unreleased_suppressed_deviations = 0
    @unreleased_valid_deviations = 0
    @scans_released = 0
    @released_suppressed_deviations = 0
    @released_valid_deviations = 0
    @released_total_valid_deviations = 0

    if @is_current == "Yes"
      @assets.each {|asset|
        @system_count += 1
        @missing_no_reason += 1 if asset[:system_scan_status] == 'Missing, no reason given'
        @available_none_labeled += 1 if asset[:system_scan_status] == 'Available, none labeled'
        @labeled_none_released += 1 if asset[:system_scan_status] == 'Labeled, none released'
        @released += 1 if asset[:system_scan_status] == 'Released'
        @missing_with_reason += 1 if asset[:system_scan_status] == 'Missing, reason provided'
      }

      @scans.each {|scan|
        if scan[:publish_ready_timestamp].nil?
          @scans_labeled_not_released += 1
#          @unreleased_unvalidated_deviations += scan[:unvalidated]
          @unreleased_suppressed_deviations += scan[:suppressed]
          @unreleased_valid_deviations += scan[:deviation_count] - scan[:suppressed]
        else
          @scans_released += 1
          @released_suppressed_deviations +=  scan[:suppressed]
          @released_valid_deviations += scan[:deviation_count] - scan[:suppressed]
        end
      }
    end

    @total_incomplete = @missing_no_reason + @available_none_labeled + @labeled_none_released
    @total_complete = @missing_with_reason + @released
    @released_total_valid_deviations = @released_suppressed_deviations + @released_valid_deviations

    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end

  #########
  private
  #########

  def get_scans(org_id, hc_group_id)
    ScanSearch.search(
    {
      "hc_group_id"=>hc_group_id,
      "org_id"=>org_id,
      "scan_tool_id"=>"all",
      "scan_type"=>"all",
      "start_date"=>"",
      "end_date"=>""
    }
    )
  end

  def get_released_scans(org_id, hc_group_id)
    PublishScanSearch.search(
    {
      "hc_group_id"=>hc_group_id,
      "org_id"=>org_id,
      "val_status"=>"all",
      "scan_type"=>"all",
      "os"=>"all",
      "publish_status"=>"all"
    }
    )
  end

end
