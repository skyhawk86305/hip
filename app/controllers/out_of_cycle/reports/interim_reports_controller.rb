class OutOfCycle::Reports::InterimReportsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  def index
  end

  def interim_scan_report
    unless params[:ooc_group_id].blank?
      ooc_scan_type = params[:ooc_scan_type]
      scan_type = OocScanType.find(ooc_scan_type)

      group = OocGroup.find params[:ooc_group_id]
      # group_name=group.ooc_group_name
      # group_name=group_name.gsub(/\W/,"_")

      org = Org.find(current_org_id)

      filename_params={
        :org_name=>org.org_name,
        :group_name=>group.ooc_group_name,
        :scan_type=>scan_type.file_name_abbreviation,
        :report_num=>"213C-01",
        :extention=>"csv"
      }

      filename = FilenameCreator.filename(filename_params)
      #filename = "#{@org_name}_#{group_name}_#{Time.now.strftime("%m-%d-%Y")}_Interim_Scan_Report.csv"
      result =  OocDeviationSearch.search(
        {:ooc_group_id=>params[:ooc_group_id],
          :ooc_scan_type=>params[:ooc_scan_type],
          :org_id=>current_org_id,
          :val_group=>"all",
          :val_status=>'all',
          :ip_address=>nil,
          :vuln_title=>nil,
          :vuln_text=>nil,
          :os=>nil,
          :host_name=>nil,
          :released=>"all",
          :clean_scans=>'yes',
          :scan_id=>nil,
          :order=>"count,host_name,validation_status,suppress_class,suppress_name",
          :row_from=>0,
          :row_to=>1,
        })
      count = result.size == 0 ? 0 : result.first.count
      per_page=64000
      if count < per_page
        per_page=count
      end
      if count > 0
        pages = (count.to_i / per_page.to_i)+1
      else
        pages=1 # create atleast one page, with headers, but no results
      end
      #group_name=group_name.gsub(/W/,"_")
      
      outfile = CSV.generate do |csv|

        csv << ["OOC Group Scan Details (#213C-01)"]
        csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
        csv << [nil] # create new line
        csv << ["Account Name: #{org.org_name}"]
        csv << ["Customer (CHIP) ID: #{org.org_ecm_account_id}"]
        csv << ["Group Name: #{group.ooc_group_name}"]
        csv << ["Scan Type: #{ooc_scan_type}"]
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
            results =  OocDeviationSearch.search(
              {:ooc_group_id=>params[:ooc_group_id],
                :ooc_scan_type=>params[:ooc_scan_type],
                :org_id=>current_org_id,
                :val_group=>"all",
                :val_status=>'all',
                :ip_address=>nil,
                :vuln_title=>nil,
                :vuln_text=>nil,
                :os=>nil,
                :host_name=>nil,
                :released=>"all",
                :clean_scans=>'yes',
                :scan_id=>nil,
                :order=>"count,host_name,validation_status,suppress_class,suppress_name",
                :row_from=>from,
                :row_to=>to,
              })
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

      send_data outfile,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => "attachment",
        :filename=>filename
    end
  end

  def inventory_group
    org = Org.find(current_org_id)
    (org_l1_id,org_id) = current_org_id.split(",")
    unless params[:format].blank?
      case params[:format].downcase
      when "pdf"
        type="application/pdf"

      when 'csv'
        type='text/csv; charset=iso-8859-1; header=present'

      end
      filename_params={
        :org_name=>org.org_name,
        :report_num=>"922C-01",
        :extention=>params[:format]
      }

      filename = FilenameCreator.filename(filename_params)
      assets = OocAssetSearch.inventory_groups({:org_id=>current_org_id,:ooc_group_id=>""})

      group_types = OocGroupType.all(:order=>:ooc_group_type)
      group_types.map!{|t| t.ooc_group_type}.insert(0,"HC Cycle")

      rows_headers =[]
      group_types.each do |t|
        header = t=="HC Cycle" ? t : t.titleize
        status = t=="HC Cycle" ? "Current" : "Status"
        rows_headers.push({:header=>"#{header} Group Name", :row=>t.downcase.gsub(" ","_")})
        rows_headers.push({:header=>"#{header} Group #{status}", :row=>"#{t.downcase.gsub(" ","_")}_status"})
      end

      outfile = CSV.generate do |csv|

        csv << ["TITLE:  Inventory Group Assignment (#922C-01) "]
        csv << ["Account: #{org.org_name}"]
        csv << ["Customer ID: #{org.org_ecm_account_id}"]
        csv << ["All Data Based on Inventory as of Last SysReg Refresh"]
        csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
        csv << [nil] # create new line
        # create headers
        headers =
          [
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
        ]
        rows_headers.each do  |rh|
          headers.push(rh[:header])
        end
        

        csv <<  headers
        assets.each do |asset|

          rows =
            [
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
          ]
          rows_headers.each do  |rh|
            rows.push(asset.attribute_for_inspect(rh[:row]).gsub(/\"|nil/,""))
          end

      
          csv << rows

        end
      end
      send_data outfile,
        :type => type,
        :disposition => "attachment",
        :filename=>filename

    end
  end

  def inventory
    org = Org.find(current_org_id)
    (org_l1_id,org_id) = current_org_id.split(",")
    unless params[:format].blank?
      case params[:format].downcase
      when "pdf"
        type="application/pdf"

      when 'csv'
        type='text/csv; charset=iso-8859-1; header=present'

      end
      filename_params={
        :org_name=>org.org_name,
        :report_num=>"222C-01",
        :extention=>params[:format]
      }

      filename = FilenameCreator.filename(filename_params)
      assets = OocAssetSearch.inventory({:org_id=>current_org_id})

      outfile = CSV.generate do |csv|

        csv << ["TITLE: Out of Cycle Inventory (#222C-01) "]
        csv << ["Account: #{org.org_name}"]
        csv << ["Customer ID: #{org.org_ecm_account_id}"]
        csv << ["All Data Based on Inventory as of Last SysReg Refresh"]
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
            Asset.find_by_tool_asset_id(asset.tool_asset_id).hc_required,
            asset.hc_auto_interval_weeks.to_s
          ]
        end
      end
      send_data outfile,
        :type => type,
        :disposition => "attachment",
        :filename=>filename

    end

  end

  def inventory_scan_status
    unless params[:format].blank?
      type='text/csv; charset=iso-8859-1; header=present'
      org = Org.find(current_org_id)

      filename_params={
        :org_name=>org.org_name,
        :report_num=>"222C-02",
        :extention=>params[:format]
      }

      filename = FilenameCreator.filename(filename_params)
      assets = OocScanSearch.inventory_scan_status({:org_id=>current_org_id,
          :ooc_group_type=>params[:ooc_group_type],
          :ooc_scan_type=>params[:ooc_scan_type]
        })



      outfile = CSV.generate do |csv|

        csv << ["TITLE:  Out of Cycle Inventory with Scan Status (#222C-01) "]
        csv << ["Account: #{org.org_name}"]
        csv << ["Customer ID: #{org.org_ecm_account_id}"]
        csv << ["All Data Based on Inventory as of Last SysReg Refresh"]
        csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
        csv << ["Scan Type: #{params[:ooc_scan_type]}"]
        csv << [nil] # create new line
        # create headers
        headers =
          [
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
          "Group Type",
          "Group Name",
          "Group Status",
          "System Scan Status",
          "Missing Reason"
        ]


        csv <<  headers
        assets.each do |asset|

          rows =
            [
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
            asset.ooc_group_type,
            asset.ooc_group_name,
            asset.ooc_group_status,
            asset.system_scan_status,
            asset.missed_scan_reason
          ]

          csv << rows

        end
      end
      send_data outfile,
        :type => type,
        :disposition => "attachment",
        :filename=>filename

    end
  end
  
  def info_warning
    unless params[:ooc_group_id].blank?
      ooc_group_id=params[:ooc_group_id]
      ooc_scan_type = params[:ooc_scan_type]
      group= OocGroup.find(ooc_group_id)
      org = Org.find(current_org_id)
      
      filename_params={
        :org_name=>org.org_name,
        :group_name=>group.ooc_group_name,
        :report_num=>"252C-01",
        :extention=>"csv"
      }
      
      filename = FilenameCreator.filename(filename_params)
      
      report_params={:title=>"Out of Cycle Interim Information & Warning Details",
        :org_id=>current_org_id,
        :ooc_group_id=>ooc_group_id,
        :ooc_scan_type => ooc_scan_type,
        :report_num=>"252C-01"
        }
      
      send_data OocInfoWarningDetail.get_report(report_params),
        :type => 'text/csv; charset=iso-8859-1;',
        :disposition => "attachment" ,
        :filename=>filename
    end
  end
end
