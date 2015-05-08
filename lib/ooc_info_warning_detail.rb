class OocInfoWarningDetail

  #
  # Disable calls to new from outside the class
  #
  private_class_method :new

  def self.get_report(params)
    search_params = new(params) 
    search_params.get_report
  end

  def get_report
    return create_report
  end


  #########
  private
  #########

  def initialize(params)
    @params = params
  end
  def org_l1_id
    @params[:org_id].split(',')[0].to_i
  end

  def org_id
    @params[:org_id].split(',')[1].to_i
  end

  def create_report
    ooc_group_id=@params[:ooc_group_id]
    ooc_scan_type=@params[:ooc_scan_type]
    group= OocGroup.find(ooc_group_id)
    
    org = Org.find(@params[:org_id])

    result = get_deviations({:org_id=>@params[:org_id],
        :ooc_group_id=>ooc_group_id,
        :ooc_scan_type=>ooc_scan_type,
        :from_row=>0,
        :to_row=>1})
    count = result.size == 0 ? 0 : result.first.count

    per_page=50000
    if count < per_page
      per_page=count
    end
    if count > 0
      pages = (count.to_i / per_page.to_i)+1
    else
      pages =1  # create atleast one page, with headers, but no results
    end
   
    # create a file for writing when running the report from schedule task
    #outfile = File.open(@params[:filename],'wb') if @params[:filename]
    
    outfile = CSV.generate do |csv|
          csv << [@params[:title]]
          #csv << ["Report for Health Check Cycle Month ENDING #{Date.new(period.year,period.month_of_year,-1).strftime("%m/%d/%Y")}"]
          csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
          csv << ["Report # #{@params[:report_num]}"]
          csv << [nil] # create new line
          csv << ["Account: #{org.org_name}"]
          csv << ["Customer (CHIP) ID: #{org.org_ecm_account_id}"]
          #csv << ["All Data Based on Inventory Locked as of: #{period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC"]
          csv << ["Out of Cycle Group: #{group.ooc_group_name}"]
          csv << ["Scan Type: #{@params[:ooc_scan_type]}"]
          csv << [nil] # create new line
          # create headers
          csv << [
            "System Name",
            "Scan Date",
            "Scan Tool",
            "Scan Release Date",
            "Deviation Level",
            "Deviation Text"
          ]
          
          pages.times do |page|
            page +=1 # need to start with 1
            to=per_page*page
            from=(to-per_page)+1
            results = get_deviations({:org_id=>@params[:org_id],
                :ooc_scan_type=>ooc_scan_type,
                :ooc_group_id=>ooc_group_id,
                :from_row=>from,
                :to_row=>to})
            results.each do |result|
              csv << [
                result.host_name,
                result.scan_start_timestamp,
                result.manager_name,
                result.publish_ready_timestamp,
                result.deviation_level,
                result.finding_text
              ]
            end
          end
       end
    #outfile.close if @params[:filename]
    return outfile
  end

  def get_deviations(params)
    OocDeviationSearch.search(
        {:ooc_group_id=>params[:ooc_group_id],
          :ooc_scan_type=>params[:ooc_scan_type],
          :org_id=>params[:org_id],
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
          :severity_id=>"2,3",
          :order=>"count,host_name,validation_status,suppress_class,suppress_name",
          :row_from=>params[:from_row],
          :row_to=>params[:to_row],
        })
  end


end