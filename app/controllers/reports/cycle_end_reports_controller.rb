class Reports::CycleEndReportsController < ApplicationController
  before_filter :select_org, :except=>:executive_dashboard
  before_filter :has_current_org_id, :except=>:executive_dashboard
  
  def index
    @show_element="reports-2"
  end

  def inventory
    @show_element="reports-2"
    org = Org.find(current_org_id)
    org_name = org.org_name.gsub(/\W/,"_")# replace space with underscore
    # create list of available dates/dirs to pick from
    # don't show account names
    dirs = Dir.glob("#{RAILS_ROOT}/reports/#{org_name}/[0-9][0-9][0-9][0-9]-[0-9][0-9]")
    #remove full path from glob
    @dirs = dirs.map!{|d|
      #extract the date from the end of the dir name.
      d[/\d{4}-\d{2}$/]#
      #works on windows, but not on hip-test (linux)  couldn't find reason.
      # d.delete("#{RAILS_ROOT}/reports/#{org_name}/")
    }
    unless params[:format].blank?
      #period = HipPeriod.current_period.first
      storage_path = "#{RAILS_ROOT}/reports/#{org_name}/#{params[:date]}"
      (year, month) = params[:date].split('-')
      file_date = Date.new(year.to_i,month.to_i,-1).strftime("%m-%d-%Y")
      case params[:format].downcase
      when "pdf"
        type="application/pdf"
        filename = "#{org_name}_#{file_date}_Inventory_Detail_Report.#{params[:format].downcase}"
      when 'csv'
        type='text/csv; charset=iso-8859-1; header=present'
        filename = "#{org_name}_#{file_date}_Inventory_Detail_Report.#{params[:format].downcase}"
      end
      if File.exist?("#{storage_path}/#{filename}")
      
        send_file "#{storage_path}/#{filename}",
          :type => type,
          :disposition => "attachment"
      else
        # the expected file doesn't exist
        flash[:error]= "The Inventory Detail (#{params[:format]}) does not exist."
        redirect_to :action=>:inventory
      end
    end
  end

  #HC Cycle Report
  def hc_cycle_report
    @show_element="reports-2"
    org = Org.find(current_org_id)
    org_name = org.org_name.gsub(/\W/,"_")# replace space with underscore
    # create list of available dates/dirs to pick from
    # don't show account names
    dirs = Dir.glob("#{RAILS_ROOT}/reports/#{org_name}/[0-9][0-9][0-9][0-9]-[0-9][0-9]")
    #remove full path from glob
    @dirs = dirs.map!{|d|
      #extract the date from the end of the dir name.
      d[/\d{4}-\d{2}$/]#
    }

    unless params[:date].blank?
      #get list of files to show user
      files = Dir.entries("#{RAILS_ROOT}/reports/#{org_name}/#{params[:date]}")
      # Only show HC Cycle Audit reports.  
      @files = files.collect!{|f| "#{f}" if  f=~/_Cycle_End_HC_Cycle_Report/}
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace_html 'result', :partial => 'hc_cycle_report_results'
          end
        }
      end
    end
  end

  def info_warning
    
    org = Org.find(current_org_id)
    org_name = org.org_name.gsub(/\W/,"_")# replace space with underscore
    # create list of available dates/dirs to pick from
    # don't show account names
    dirs = Dir.glob("#{RAILS_ROOT}/reports/#{org_name}/[0-9][0-9][0-9][0-9]-[0-9][0-9]")
    #remove full path from glob
    @dirs = dirs.map!{|d|
      #extract the date from the end of the dir name.
      d[/\d{4}-\d{2}$/]#
    }

    unless params[:date].blank?
      #get list of files to show user
      files = Dir.entries("#{RAILS_ROOT}/reports/#{org_name}/#{params[:date]}")
      # Only show HC Cycle Audit reports.  
      @files = files.collect!{|f| "#{f}" if  f=~/152C/}
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace_html 'result', :partial => 'info_warning_results'
          end
        }
      end
    end
  end
  def get_file
    org = Org.find(current_org_id)
    org_name = org.org_name.gsub(/\W/,"_")
    storage_path = "#{RAILS_ROOT}/reports/#{org_name}/"
    send_file "#{storage_path}/#{params[:file]}",
#      :type => type,
      :disposition => "attachment"
  end
  #export inventory report to a csv file
 
  def valid_deviations_report
    @show_element="reports-2"

    unless params[:hc_group_id].blank?
      hc_group_id=params[:hc_group_id]
      group= HcGroup.find(hc_group_id)
      group_name=group.group_name.gsub(/\W/,"_")
      period = HipPeriod.current_period.first
      org = Org.find(current_org_id)

      deviations = DeviationSearch.search(
        {"hc_group_id"=>hc_group_id,
          "org_id"=>current_org_id,
          "val_group"=>"all",
          "val_status"=>'valid',
          "ip_address"=>nil,
          "vuln_title"=>nil,
          "vuln_text"=>nil,
          "suppress_id"=>nil,
          "os"=>nil,
          "host_name"=>nil,
          "not_released"=>"no",
          "scan_id"=>nil,
          "order"=>"host_name,validation_status,suppress_class,suppress_name"
        },0,2)
        
      count = deviations.size == 0 ? 0 : deviations.first[:count]
      Rails.logger.debug { "CycleEndReportsController: valid_deviations_report: count: #{count}" }

      per_page=64000
      if count < per_page
        per_page=count
      end
      if count > 0
        pages = (count.to_i / per_page.to_i)+1
      else
        pages =1  # create atleast one page, with headers, but no results
      end
      Rails.logger.debug { "CycleEndReportsController: valid_deviations_report: pages #{pages}" }

      outfile = CSV.generate do |csv|
        csv << ["Cycle End Valid Deviation Tracking Template"]
        csv << ["Report for Health Check Cycle Month ENDING #{Date.new(period.year,period.month_of_year,-1).strftime("%m/%d/%Y")}"]
        csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
        csv << [nil] # create new line
        csv << ["Account: #{org.org_name}"]
        csv << ["Customer (CHIP) ID: #{org.org_ecm_account_id}"]
        csv << ["All Data Based on Inventory Locked as of: #{period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC"]
        csv << ["HC Cycle Group: #{group.group_name}"]
        csv << [nil] # create new line
        csv << ["NOTE: Only Valid Deviations from RELEASED scans are included in this tracking document."]
        # create headers
        csv << [
          "System Name",
          "Scan Date",
          "Scan Tool",
          "Deviation Validation Group",
          "Deviation Level",
          "Deviation Text",
          "Deviation Status",
          "Fix Time (# of calendar days)",
          "Remediation Due Date",
          "Remediation Team",
          "CIRATS NCI #",
          "SA Name",
          "Change Record (CR) #",
          "CR Implementation date",
          "*NEW* False Positive? (Y.N)",
          "How *NEW* FP Verified"
        ]
        pages.times do |page|
          Rails.logger.debug { "CycleEndReportsController: valid_deviations_report: page: #{page}" }
          page +=1 # need to start with 1
          to=per_page*page
          from=(to-per_page)+1
          results = DeviationSearch.search(
            {"hc_group_id"=>hc_group_id,
              "org_id"=>current_org_id,
              "val_group"=>"all",
              "val_status"=>'valid',
              "ip_address"=>nil,
              "vuln_title"=>nil,
              "vuln_text"=>nil,
              "suppress_id"=>nil,
              "os"=>nil,
              "host_name"=>nil,
              "not_released"=>"no",
              "scan_id"=>nil,
              "order"=>"host_name,validation_status,suppress_class,suppress_name"
            },from, to)

          results.each do |result|
            csv << [
                result.host_name,
                result.scan_start_timestamp,
                result.manager_name,
                result.cat_name.nil? ? result.sarm_cat_name : result.cat_name,
                result.deviation_level,
                result.finding_text,
                result.validation_status,

                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
              ]
          end
        end
      end
      filename="#{org.org_name.gsub(/\W/,"_")}_#{group_name}_#{Time.now.strftime("%m-%d-%Y")}_Cycle_End_Valid_Deviations_Tracking_Document.csv"
      send_data outfile,
        :type => 'text/csv; charset=iso-8859-1; header=present',
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

  # put the systems and attributes into an array
  # with column names for use with csv and pdf table.
  def assets_to_array(assets,period_id)
    # column headers for csv and pdf table.
    system_scan_status=get_system_scan_status()
    items=[]
    items.push(
      [
        "*System Name",
        "*IP Address",
        "*Operating System",
        "**System Status",
        "*HC Auto Flag? (Y/N)",
        "*HC Auto Interval",
        "*HC Man Flag? (Y/N)",
        "*HC Man Interval",
        "**HC Required? (Y/N)",
        "*HC Frequency Interval (wks)",
        "HC Cycle Group",
        "Current HC Cycle (Y,N)",
        "System Scan Status",
        "Missing Reason"]
    )
    assets.each do |asset|
      asset_group=asset.asset_group
      items.push([
          asset.host_name.to_s,
          asset.ip_string_list.to_s ,
          asset.os.os_product.to_s,
          asset.system_status.to_s,
          asset.hc_auto_flag.to_s,
          asset.hc_auto_interval_weeks.to_s,
          asset.hc_manual_flag.to_s,
          asset.hc_manual_interval_weeks.to_s,
          asset.hc_required.to_s,
          asset.hc_auto_interval_weeks.to_s,
          asset_group.nil? ? 'unassigned': asset_group.hc_group.group_name.to_s ,
          asset_group.nil? ? "" : asset_group.hc_group.is_current.to_s ,
          asset_group.nil? ? "" : system_scan_status[asset.host_name].to_s,
          get_missed_scan_reason(asset.tool_asset_id,period_id).to_s]
      )

    end
    return items
  end

  def deviations_to_array(results)
    items = [
      ["System Name",
        "Scan Tool",
        "Finding / Deviation Text",
        "Deviation Status",
        "Suppression Classification",
        "Suppression Name"]
    ]
    results.each do |result|
      items.push([
          result.host_name.to_s,
          result.manager_name.to_s,
          "",
          result.validation_status.to_s,
          result.suppress_class.to_s,
          result.suppress_name.to_s
        ])
    end
    return items
  end

  def get_deviations(hc_group_id, not_released=nil)
    DeviationSearch.search(
      {"hc_group_id"=>hc_group_id,
        "org_id"=>current_org_id,
        "val_group"=>"all",
        "val_status"=>'all',
        "ip_address"=>nil,
        "vuln_title"=>nil,
        "vuln_text"=>nil,
        "suppress_id"=>nil,
        "os"=>nil,
        "host_name"=>nil,
        "not_released"=>not_released,
        "scan_id"=>nil,
        "order"=>"ah.host_name,validation_status,sup.suppress_class,sup.suppress_name"
      })
  end

  def deviation_csv(hc_group_id,host_name = nil)
    period = HipPeriod.current_period.first
    org = Org.find(current_org_id)
    results = DeviationSearch.search(
      {"hc_group_id"=>hc_group_id,
        "org_id"=>current_org_id,
        "val_group"=>"all",
        "val_status"=>'all',
        "ip_address"=>nil,
        "vuln_title"=>nil,
        "vuln_text"=>nil,
        "suppress_id"=>nil,
        "os"=>nil,
        "host_name"=>host_name,
        "not_released"=>'yes',
        "scan_id"=>nil,
        "order"=>"ah.host_name,validation_status,sup.suppress_class,sup.suppress_name"
      })

    outfile = CSV.generate do |csv|
      csv << ["Health Check Cycle REPORT"]
      csv << ["Report for Health Check Cycle Month ENDING #{Date.new(period.year,period.month_of_year,-1).strftime("%m/%d/%Y")}"]
      csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << [nil] # create new line
      csv << ["Account: #{org.org_name}"]
      csv << ["Customer (CHIP) ID: #{org.org_ecm_account_id}"]
      csv << ["All Data Based on Inventory Locked as of: #{period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << ["HC Cycle Group: #{HcGroup.find(hc_group_id).group_name}"]
      csv << [nil] # create new line
      # create headers
      csv << [
        "System Name",
        "Scan Tool",
        "Finding / Deviation Text",
        "Deviation Status",
        "Suppression Classification",
        "Suppression Name",
      ]
      results.each do |result|
        csv << [
          result.host_name,
          result.tool.manager_name,
          result.finding_text,
          result.validation_status,
          result.suppress_class,
          result.suppress_name
        ]
      end
    end
    filename="#{org.org_name.gsub(/\W/,"_")}_" + Time.now.strftime("%m-%d-%Y") + "_HC_Cycle_Report.csv"
    send_data outfile,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment" ,
      :filename=>filename
  end
end
