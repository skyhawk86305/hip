class InfoWarningDetail

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
    hc_group_id=@params[:hc_group_id]
    group= HcGroup.find(hc_group_id)
    period = HipPeriod.current_period.first
    org = Org.find(@params[:org_id])
    per_page=50000
    
    results = get_deviations({:org_id=>@params[:org_id],:hc_group_id=>hc_group_id,:from_row=>0,:to_row=>per_page})
    
    count = results.size == 0 ? 0 : results.first.count
    
    if count < per_page
      per_page=count
    end
    if count > 0
      pages = (count.to_i / per_page.to_i)+1
    else
      pages =1  # create atleast one page, with headers, but no results
    end
   
    outfile = ''
    if @params[:filename].nil?
      csv = CSV.new(outfile)
    else
      RAILS_DEFAULT_LOGGER.debug "InfoWarningDetail#create_report: @params[:filename]: #{@params[:filename].inspect}"
      csvfile = File.new(@params[:filename],'wb')
      csv = CSV.new(csvfile)
    end
    
    csv << [@params[:title]]
    csv << ["Report for Health Check Cycle Month ENDING #{Date.new(period.year,period.month_of_year,-1).strftime("%m/%d/%Y")}"]
    csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
    csv << ["Report # #{@params[:report_num]}"]
    csv << [nil] # create new line
    csv << ["Account: #{org.org_name}"]
    csv << ["Customer (CHIP) ID: #{org.org_ecm_account_id}"]
    csv << ["All Data Based on Inventory Locked as of: #{period.asset_freeze_timestamp.strftime("%m/%d/%Y %H:%M")} UTC"]
    csv << ["HC Cycle Group: #{group.group_name}"]
    csv << ["Scan Type: HC Cycle"]
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
      unless page == 1
        results = get_deviations({:org_id=>@params[:org_id],:hc_group_id=>hc_group_id,:from_row=>from,:to_row=>to})
      end
      results.each do |result|
        if !result.row.nil?
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
    csvfile.close unless @params[:filename].nil?
    return outfile
  end

  def get_deviations(params)
    (org_l1_id,org_id)=params[:org_id].split(',')
    sql = "with groups as (
    select g.*
    from hip_hc_group_v as g
    where g.hc_group_id = #{params[:hc_group_id]}
    and org_l1_id=#{org_l1_id} and org_id=#{org_id}
    ),
    orgs as (
    select o.*
    from dim_comm_org_v as o
    where (org_l1_id, org_id) in (select distinct org_l1_id, org_id from groups)
    ),
    assets as (
    select a.*
    from dim_comm_tool_asset_hist_v as a
    join hip_asset_group_v as ag on ag.asset_id = a.tool_asset_id
    join groups as g on g.hc_group_id = ag.hc_group_id
    where a.system_status = 'prod'
    and #{SwareBase.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between a.row_from_timestamp and coalesce(a.row_to_timestamp, current_timestamp)
    ),
    scans as (
    select dssp.*
    from assets as a
    --join dim_comm_tool_asset_scan_hist_v as s on s.asset_id = a.tool_asset_id
    --join hip_scan_v as hs on hs.scan_id = s.scan_id
    join dim_scan_scan_period_v as dssp on dssp.asset_vid=a.tool_asset_vid
    and dssp.period_month_id = #{SwareBase.current_month_period_id}
    ),
    latest_scans as (
    select ls.*
    from scans as ls
    -- The following coalesces will cause an unreleased scan to be selected
    where coalesce(ls.publish_ready_timestamp, '9999-12-31 00:00:00') =
      ( select coalesce(s.publish_ready_timestamp, '9999-12-31 00:00:00')
        from scans as s
       -- where s.asset_id = ls.asset_id
        where s.asset_vid = ls.asset_vid
        order by (coalesce(s.publish_ready_timestamp, '9999-12-31 00:00:00')) desc
        fetch first 1 row only
      )
    ),
    supf as (
    select sf.*
    from orgs as o
    join hip_suppress_v as s on s.org_l1_id = o.org_l1_id
      and s.org_id = o.org_id
      and #{SwareBase.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between s.start_timestamp and s.end_timestamp
    join hip_suppress_finding_v as sf on sf.suppress_id = s.suppress_id
    ),
    facts as (
    select f.*,
      sf.suppress_id,
      case when sf.suppress_id is not null then 'y' else 'n' end as suppress_flag,
      s.scan_id
    from latest_scans as s
      join assets as a on a.tool_asset_vid=s.asset_vid
      join fact_scan_v as f on f.asset_id = a.tool_asset_id
    --join fact_scan_v as f on f.asset_id = s.asset_id
      and f.org_l1_id = s.org_l1_id
      and f.org_id = s.org_id
      and f.scan_service = 'health'
      and f.vuln_id not in (#{SwareBase.vuln_ids_to_ignore})
      and s.scan_start_timestamp between f.row_from_timestamp and coalesce(f.row_to_timestamp, current_timestamp)
      and f.severity_id != 5
      and f.scan_tool_id = s.tool_id
      left join supf as sf on sf.finding_id = f.finding_id
    ),
    data_with_row as (
      select
        cast(null as integer) as count,
        a.host_name,
        scan.scan_start_timestamp,
        scan.publish_ready_timestamp,
        t.manager_name,
        CASE WHEN sev.severity_cd = 'allowed' THEN 'compliant'
            WHEN sev.severity_cd = 'low' THEN 'warning'
            WHEN sev.severity_cd = 'high' THEN 'violation'
              ELSE sev.severity_cd
            END AS deviation_level,
        f.finding_text,
        row_number() over(ORDER BY f.finding_vid) as row
        from facts as f
        join dim_comm_tool_v as t on t.tool_id=f.scan_tool_id
        --join dim_comm_tool_asset_scan_hist_v as sh on sh.scan_id=f.scan_id
        join scans as scan on scan.scan_id=f.scan_id
        join assets as a on a.tool_asset_id = f.asset_id
        join dim_comm_severity_v as sev on sev.severity_id=f.severity_id
        --left join hip_scan_v as scan on scan.scan_id=sh.scan_id
    )
     SELECT * FROM data_with_row
        WHERE row BETWEEN #{params[:from_row]} AND #{params[:to_row]}
        UNION
        SELECT count(*) as count,
        cast(null as varchar(1)) as host_name,
        cast(null as varchar(1)) as scan_start_timestamp,
        cast(null as varchar(1)) as publish_ready_timestamp,
        cast(null as varchar(1)) as manager_name,
        cast(null as varchar(1)) as deviation_level,
        cast(null as varchar(1)) as finding_text,
        cast(null as integer) as row
        FROM data_with_row
        ORDER BY count asc, host_name asc"
    SwareBase.find_by_sql sql
  end


end