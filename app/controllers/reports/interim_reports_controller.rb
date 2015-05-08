class Reports::InterimReportsController < ApplicationController
  before_filter :select_org, :except=>:executive_dashboard
  before_filter :has_current_org_id, :except=>:executive_dashboard
  
  def index
    @show_element="reports-2"
  end

  
  #HC Cycle Report
  # creates a tmp csv file and returned to the user with
  # each request.
  def interim_hc_cycle_report
    @show_element="reports-2"

    unless params[:hc_group_id].blank?
      group = HcGroup.find params[:hc_group_id]
      group_name=group.group_name
      group_name=group_name.gsub(/\W/,"_")
      
      org = Org.find(current_org_id)
      @org_name = org.org_name.gsub(/\W/,"_")# replace space with underscore
      filename = "#{@org_name}_#{group_name}_#{Time.now.strftime("%m-%d-%Y")}_Interim_HC_Cycle_Report.csv"
      deviations =  DeviationSearch.search(
        {"hc_group_id"=>params[:hc_group_id],
          "org_id"=>current_org_id,
          "val_group"=>"all",
          "val_status"=>'all',
          "ip_address"=>nil,
          "vuln_title"=>nil,
          "vuln_text"=>nil,
          "suppress_id"=>nil,
          "os"=>nil,
          "host_name"=>nil,
          "not_released"=>"all",
          "clean_scans"=>'yes',
          "scan_id"=>nil,
          "order"=>"host_name,validation_status,suppress_class,suppress_name"
        },0,2)
      count = deviations.size == 0 ? 0 : deviations.first[:count]
      per_page=64000
      if count < per_page
        per_page=count
      end
      if count > 0
        pages = (count.to_i / per_page.to_i)+1
      else
        pages=1 # create atleast one page, with headers, but no results
      end
      period = HipPeriod.current_period.first
      group_name=group_name.gsub(/W/,"_")
      tmpfile = "#{RAILS_ROOT}/tmp/hc_cycle_report.#{Time.now.to_i}"
      CSV.open(tmpfile, 'wb') do |csv|

        csv << ["Interim HC Cycle Report"]
        csv << ["Interim Report for HC Cycle Month ENDING #{Date.new(period.year,period.month_of_year,-1).strftime("%m/%d/%Y")}"]
        csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
        csv << [nil] # create new line
        csv << ["Account Name: #{org.org_name}"]
        csv << ["Customer (CHIP) ID: #{org.org_ecm_account_id}"]
        csv << ["All Data Based on Inventory Locked as of: #{period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC"]
        csv << ["HC Cycle Group: #{group_name}"]
        csv << [nil] # create new line
        # create headers
        csv << [
          "System Name",
          "Scan Date",
          "Scan Tool",
          "Release Date",
          "Deviation Level",
          "Finding / Deviation Text",
          "Deviation Validation Group",
          "Deviation Status",
          "Suppression Classification",
          "Suppression Name",
        ]
        if count > 0
          pages = (count.to_i / per_page.to_i)+1
          pages.times do |page|
            page +=1 # need to start with 1
            to=per_page*page
            from=(to-per_page)+1
            results =  DeviationSearch.search(
              {"hc_group_id"=>params[:hc_group_id],
                "org_id"=>current_org_id,
                "val_group"=>"all",
                "val_status"=>'all',
                "ip_address"=>nil,
                "vuln_title"=>nil,
                "vuln_text"=>nil,
                "suppress_id"=>nil,
                "os"=>nil,
                "host_name"=>nil,
                "not_released"=>"all",
                "clean_scans"=>'yes',
                "scan_id"=>nil,
                "order"=>"host_name,validation_status,suppress_class,suppress_name"
              },from,to)
            results.each do |result|
              csv << [
                  result.host_name,
                  result.scan_start_timestamp,
                  result.manager_name,
                  result.publish_ready_timestamp.nil? ? "Not Released":Time.parse(result.publish_ready_timestamp).strftime("%Y-%m-%d %H:%M:%S"),
                  result.deviation_level,
                  result.title=="Scan Successful" ? "HC Scanner found NO deviations":result.finding_text,
                  result.cat_name.nil? ? result.sarm_cat_name : result.cat_name,
                  result.validation_status,
                  result.suppress_class,
                  result.suppress_name
                ]
            end
          end
        end
      end

      send_file tmpfile,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => "attachment",
        :filename=>filename
    end
  end

  def interm_inventory_csv
    org = Org.find(current_org_id)
    period = HipPeriod.current_period.first
    assets = AssetSearch.inventory_detail_report(org.id.to_s)
    system_scan_status=get_system_scan_status()
    outfile = CSV.generate do |csv|
      csv << ["TITLE: Interim Inventory Detail Report"]
      csv << ["Account: #{org.org_name}"]
      csv << ["Customer ID: #{org.org_ecm_account_id}"]
      csv << ["Interim Inventory Detail Report for Health Check Cycle Month: #{Date.new(period.year,period.month_of_year).strftime("%B %Y")}"]
      csv << ["All Data Based on Inventory Locked as of: #{period.asset_freeze_timestamp.strftime("%m/%d/%Y %H%M")} UTC"]
      csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << [nil] # create new line
      # create headers
      csv << [
        "System Name",
        "IP Address",
        "Operating System",
        "System Status",
        "HC Auto Flag? (Y/N)",
        "HC Auto Interval",
        "HC Man Flag? (Y/N)",
        "HC Man Interval",
        "HC Required? (Y/N)",
        "HC Frequency Interval (wks)",
        "HC Cycle Group",
        "Current HC Cycle (Y,N)",
        "System Scan Status",
        "Missing Reason"
      ]
      assets.each do |asset|
        csv << [
          asset.host_name,
          asset.ip_string_list,
          asset.os_product,
          asset.system_status,
          asset.hc_auto_flag,
          asset.hc_auto_interval_weeks.to_s,
          asset.hc_manual_flag,
          asset.hc_manual_interval_weeks.to_s,
          asset.hc_required,
          asset.hc_auto_interval_weeks.to_s,
          asset.group_name.nil? ? 'unassigned': asset.group_name ,
          asset.is_current ,
          system_scan_status[asset.host_name],
          asset.missed_scan_reason
        ]
      end
    end
    filename="#{org.org_name.gsub(/\W/,"_")}_#{Time.now.strftime("%m-%d-%Y")}_Interim_Inventory_Detail_Report.csv"
    send_data outfile,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment" ,
      :filename=>filename
  end

  def info_warning
    unless params[:hc_group_id].blank?
      hc_group_id=params[:hc_group_id]
      group= HcGroup.find(hc_group_id)
      org = Org.find(current_org_id)
      
      filename_params={
        :org_name=>org.org_name,
        :group_name=>group.group_name,
        :report_num=>"152C-01",
        :extention=>"csv"
      }
      
      filename = FilenameCreator.filename(filename_params)
      
      report_params={:title=>"In-Cycle Interim Information & Warning Details",
        :org_id=>current_org_id,
        :hc_group_id=>hc_group_id,
        :report_num=>"152C-01"
        }
      
      send_data InfoWarningDetail.get_report(report_params),
        :type => 'text/csv; charset=iso-8859-1;',
        :disposition => "attachment" ,
        :filename=>filename
    end
  end

  private
  # returns a hash of systems and their system_scan_status
  def get_system_scan_status
    scans = ScanSearch.search({
        "hc_group_id"=>'all',
        "org_id"=>current_org_id,
        "scan_tool_id"=>"all",
        "scan_type"=>"",
        "start_date"=>"",
        "end_date"=>"",
        'system_scan_status'=>"all",
        "host_name"=>''
      })
    system_scan_status_by_asset=Hash.new()
    scans.each do |s|
      system_scan_status_by_asset[s.host_name]=s.system_scan_status.nil? ? "":s.system_scan_status
    end
    return system_scan_status_by_asset
  end

  # lookup missing scans reason from asset_id
  # need to lookup period_id, then get the missed_scan_id to then
  # retreive the reason
  def get_missed_scan_reason(asset_id,period_id)
    ms = MissedScan.find(:first,:conditions=>{:asset_id=>asset_id,:period_id=>period_id})
    unless ms.nil?
      msr = MissedScanReason.find(ms.missed_scan_reason_id)
    end
    msr.nil? ? "":msr.missed_scan_reason
  end

end
