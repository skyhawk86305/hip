class OutOfCycle::Reports::FinalOocReportsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
 

  #  include RetentionScanReport
  def index

  end

  def valid_deviations_report
    unless params[:ooc_group_id].blank?
      ooc_group_id = params[:ooc_group_id]
      ooc_scan_type = params[:ooc_scan_type]
      #scan_type = OocScanType.find(params[:ooc_scan_type])

      group= OocGroup.find(ooc_group_id)
      group_name=group.ooc_group_name.gsub(/\W/,"_")

      scan_type = OocScanType.find(ooc_scan_type)
      org = Org.find(current_org_id)

      result = OocDeviationSearch.search(
        {:ooc_group_id=>ooc_group_id,
          :ooc_scan_type=>ooc_scan_type,
          :org_id=>current_org_id,
          :val_group=>"all",
          :val_status=>'valid',
          :ip_address=>nil,
          :vuln_title=>nil,
          :vuln_text=>nil,
          :suppress_id=>nil,
          :os=>nil,
          :host_name=>nil,
          :released=>"yes",
          :order=>"count,host_name,validation_status,suppress_class,suppress_name",
          :row_from=>0,
          :row_to=>1,
        })
      count = result.size == 0 ? 0 : result.first.count
      Rails.logger.debug { "FinalOocReportsController: valid_deviations_reoprt: count: #{count}" }

      per_page=64000
      if count < per_page
        per_page=count
      end
      if count > 0
        pages = (count.to_i / per_page.to_i)+1
      else
        pages =1  # create atleast one page, with headers, but no results
      end

      outfine = CSV.generate do |csv|

        csv << ["Valid Deviation Tracking Template (#A-213C-02)"]
        csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
        csv << [nil] # create new line
        csv << ["Account: #{org.org_name}"]
        csv << ["Customer (CHIP) ID: #{org.org_ecm_account_id}"]
        csv << ["Group Name: #{group.ooc_group_name}"]
        csv << ["Scan Type: #{ooc_scan_type}"]
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
          page +=1 # need to start with 1
          to=per_page*page
          from=(to-per_page)+1
          results = OocDeviationSearch.search(
            {:ooc_group_id=>ooc_group_id,
              :ooc_scan_type=>ooc_scan_type,
              :org_id=>current_org_id,
              :val_group=>"all",
              :val_status=>'valid',
              :ip_address=>nil,
              :vuln_title=>nil,
              :vuln_text=>nil,
              :suppress_id=>nil,
              :os=>nil,
              :host_name=>nil,
              :released=>"yes",
              :order=>"count,host_name,validation_status,suppress_class,suppress_name",
              :row_from=>from,
              :row_to=>to
            })

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
      filename_params={
        :org_name=>org.org_name,
        :group_name=>group.ooc_group_name,
        :scan_type=>scan_type.file_name_abbreviation,
        :report_num=>"A-213C-02",
        :extention=>"csv"
      }

      filename = FilenameCreator.filename(filename_params)
      send_data outfile,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => "attachment" ,
        :filename=>filename
    end
  end

  def scan_report
    org = Org.find(current_org_id)
    org_name = org.org_name.gsub(/\W/,"_")# replace space with underscore
    @dirs = Dir.glob("#{RAILS_ROOT}/reports/#{org_name}/[0-9][0-9][0-9][0-9]-[0-9][0-9]")
    @dirs.map!{|d|
      d[/\d{4}-\d{2}$/]
    }
    unless params[:ooc_scan_type].blank?
      
      scan_type = OocScanType.find(params[:ooc_scan_type])
      unless params[:asset][:host_name].blank?
        group = OocGroup.find(params[:ooc_group_id])
        asset = Asset.find_by_host_name(params[:asset][:host_name])
        host_name = params[:asset][:host_name].blank? ? nil:params[:asset][:host_name]
        
        #find the latest scan for the host.
        unless asset.nil?
        scan = OocScan.find(:all, :conditions => "publish_ready_timestamp is not null 
        and ooc_group_id = #{group.ooc_group_id} and ooc_scan_type = #{SwareBase.quote_value(scan_type)} and asset_id=#{asset.tool_asset_id}",
        :order =>"publish_ready_timestamp asc").first
        else
          flash.now[:error]="System Name #{params[:asset][:host_name]} not found "
        end
      
        filename_params={
          :org_name=>org.org_name,
          :group_name=>group.ooc_group_name,
          :host_name=>host_name,
          :scan_type=>scan_type.file_name_abbreviation,
          :report_num=>"A-214P-01",
          :extention=>"pdf"
        }
        unless scan.nil?
        html = OocFinalSystemScanReportDetail.get_report(org, group, scan, asset)
     
        kit = PDFKit.new(html,
          :header_left => "System Final Scan Details (#A-214P-01) System Name: #{params[:asset][:host_name]}"
        )
        
        send_data kit.to_pdf,
          :type => 'application/pdf',
          :disposition => "attachment" ,
          :filename=>FilenameCreator.filename(filename_params)
        else
          flash.now[:error] = "There were no scans found for system name #{params[:asset][:host_name]}"
        end
      else
       
        dirs = Dir.glob("#{RAILS_ROOT}/reports/#{org_name}/#{params[:date]}")
        dirs.map!{|d|
          d[/\d{4}-\d{2}$/]
        }
       
        
        @files = [{}]
        dirs.reverse_each do |dir|
          files = Dir.glob("#{RAILS_ROOT}/reports/#{org_name}/#{dir}/*#{scan_type.file_name_abbreviation}*A-214P-01*.zip")
          unless files.empty?
            @files.push(:date=>dir, :files=>files.map{|f| "#{f.sub("#{RAILS_ROOT}/reports/#{org_name}/#{dir}/",'')}"}  )
          end
        end


        respond_to do |format|
          format.js {
            render :update do |page|
              page.replace_html 'result', :partial => 'final_system_scans_results'
            end
          }
        end

      end


    end
  end

  # action to populate the autocomplete field
  def auto_complete_for_asset_host_name
    host_name=params[:asset][:host_name]
    ooc_group_id = params[:ooc_group_id]
    (org_l1_id,org_id) = current_org_id.split(",")
    @assets = SwareBase.find_by_sql("select distinct host_name from dim_comm_tool_asset_hist_v ah
      join hip_ooc_asset_group_v as ag on ag.asset_id=ah.tool_asset_id
      where ag.ooc_group_id=#{ooc_group_id}
      and ah.org_l1_id=#{org_l1_id} and ah.org_id=#{org_id}
      and ah.system_status!='decom'
      and LOWER(host_name) LIKE '%#{host_name.downcase}%'
      order by host_name
      fetch first 20 row only")

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def get_file
    org = Org.find(current_org_id)
    org_name = org.org_name.gsub(/\W/,"_")
    storage_path = "#{RAILS_ROOT}/reports/#{org_name}/"
    send_file "#{storage_path}/#{params[:file]}",
      :type => type,
      :disposition => "attachment"
  end
  private

end
