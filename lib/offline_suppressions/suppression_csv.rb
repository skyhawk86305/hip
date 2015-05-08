class OfflineSuppressions::SuppressionCsv

  TEMP_TABLE_NAME = 'suppressioncsv'
  START_ROW = 9
  ALLOWABLE_ERRORS = APP['offline_suppression_background_count']
  REMOVE_SUPPRESSION_NAME = '<remove>'

  # create the csv file for download
  def self.create_csv(params)
    per_page=10000
    result = get_deviations(params,0,2)
    count = result.size == 0 ? 0 : result.first.count

    if count < per_page
      per_page=count
    end
    if count > 0
      pages = ((count.to_i - 1) / per_page.to_i) + 1  
    end

    #section = params[:section].nil? ? params['section']:params[:section]


    org_id = params[:deviation_search][:org_id]

    scan_type=params[:st].nil? ? "":"Scan Type: #{params[:st]}"

    (l1_id,id) = org_id.split(',')
    between_timestamp = Time.now.end_of_month.strftime("%Y-%m-%d %H:%M:%S.0")
    suppressions = Suppression.all(:conditions=>
    ["org_l1_id=? and org_id=? and automatic_suppress_flag = 'n' and ? between start_timestamp and end_timestamp",l1_id,id,between_timestamp])

    dir_name= "#{RAILS_ROOT}/reports/offline_suppression/#{org_id.sub(",","_")}"
    FileUtils.makedirs(dir_name)
    CSV.open("#{dir_name}/#{params[:filename]}", "w") do |csv|
      csv << ["Title: Offline Suppression Management"]
      csv << ["Account Name: #{Org.find(org_id).org_name}"]
      csv << ["Group: #{params[:g]}",scan_type]
      csv << ["File Create Time: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")} UTC"]
      csv << ["Available Suppressions:" ,suppressions.map!{|s| s.suppress_name}].flatten
      #csv << suppressions.map!{|s| s.suppress_name} 
      csv << ["WARNING: Do not remove or add lines above this line"]
      csv << []
      csv << [
        "System Name",
        "IP address",
        "Operation System",
        "Group Name",
        "Deviation Level",
        "Suppression Name",
        "Suppression Date",
        "Deviation Text",  
        "Deviation Status",
        "Deviation Validation Group",
        "HC Cycle Scan Timestamp",
        "finding_vid",
        "finding_hash",
        "asset_id",
      ]

      if count > 0
        pages.times do |page|
          page +=1 
          to=per_page*page
          from=(to-per_page)+1
          result = get_deviations(params,from,to)
          result.each do |row|
            csv << [row.host_name,
              row.ip_string_list,
              row.os_product,
              row.group_name,
              row.deviation_level,  
              row.suppress_name,  
              row.suppress_date,
              row.finding_text,
              row.validation_status,
              row.cat_name.nil? ? row.sarm_cat_name : row.cat_name ,
              row.scan_start_timestamp,
              row.finding_vid,
              row.finding_hash,
              row.asset_id,
            ]
          end
        end
      end
    end
  end

  def self.process(params)
    file="#{APP['offline_suppression_files_path']}/#{params['fn']}"
    userid = params['u']
    composit_org_id = params['org_id']
    group_name = params['g']
    section = params['s']
    scan_type = params['st']

    #
    # fetch the data might be needed for this request
    #
    group_id = group_name_to_id(section, composit_org_id, group_name)
    if group_id.nil?
      group_status = section == 'ooc' ? 'active' : 'current'
      return ["Group #{group_name} not found or is not #{group_status}"]
    end
    (findings, suppress_findings) = get_findings(section, composit_org_id, group_id, scan_type)
    suppressions = get_suppressions(composit_org_id)

    #
    # Gather data from the CSV file and collect the actions that are needed
    #
    errors = []
    to_apply = []
    to_delete = []
    processed = {}
    row_number = 0
    processed_lines = 0
    CSV.foreach(file,{:headers=>false}) do |row|
      row_number += 1
      if row_number >= START_ROW and row.any? {|s| s.present?}
        processed_lines += 1

        # Pull out data from CSV row and convert
        finding_vid = row[11].to_s.to_i
        finding_hash = row[12].to_s.blank? ? nil : row[12].to_s
        finding_asset_id = row[13].to_s.to_i
        finding_suppression_name = row[5].to_s.blank? ? nil : row[5].to_s
        finding_validation_group = row[9].to_s.blank? ? nil : row[9].to_s

        # Verify data from CSV
        finding_id = validate_finding(findings, finding_vid, finding_hash, finding_asset_id)
        suppress_id = validate_suppression(suppressions, finding_suppression_name)

        # Look for errors
        if finding_vid == 0
          errors << "finding_vid is 0 or not a number in CSV file: line # #{row_number}"
          already_processed?(processed, finding_id, suppress_id, :error, row_number, errors)
        elsif finding_hash.nil?
          errors << "finding_hash is empty in CSV file: line # #{row_number}"
          already_processed?(processed, finding_id, suppress_id, :error, row_number, errors)
        elsif finding_asset_id == 0
          errors << "asset_id is 0 or not a number in CSV file: line # #{row_number}"
          already_processed?(processed, finding_id, suppress_id, :error, row_number, errors)
        elsif finding_id.nil?
          errors << "Incorrect deviation found in CSV file: line # #{row_number}"
          already_processed?(processed, finding_id, suppress_id, :error, row_number, errors)
        elsif suppress_id.nil? && !finding_suppression_name.blank?
          errors << "Suppression Name '#{finding_suppression_name}' not found or is expired: line # #{row_number}"
          already_processed?(processed, finding_id, suppress_id, :error, row_number, errors)
        else
          # Validation of the finding and the suppression have passed (i.e. no errors)
          # Determine what needs to be done for the row
          if finding_suppress_match(suppress_findings, finding_id, suppress_id)
            # do nothing except track for validation -- it isn't changing
            already_processed?(processed, finding_id, suppress_id, :nothing, row_number, errors)
          elsif suppress_id.nil?
            # do nothing except track for validation -- these rows have a blank suppression name are are ignored
            already_processed?(processed, finding_id, suppress_id, :nothing, row_number, errors)
          elsif suppress_id == 0
            # coollect the findings to delete all suppressions from because it souldn't be suppressed
            if !already_processed?(processed, finding_id, suppress_id, :delete, row_number, errors)
              to_delete << {:finding_id => finding_id}
            else
            end
          else # collect the finding/suppression pairs to delete all the existing suppression, and apply the current one
            # collect to apply new suppression
            if !already_processed?(processed, finding_id, suppress_id, :update, row_number, errors)
              to_apply << {:finding_id => finding_id, :suppress_id => suppress_id, :lu_userid => userid}
            end
          end
        end # if finding_vid == 0
        break if errors.size > ALLOWABLE_ERRORS
      end # if row_num >= START_ROW
    end # CSV.foreach

    critical_error = errors.find {|m| m =~ /^critical/i }
    if errors.size > ALLOWABLE_ERRORS || critical_error
      if critical_error
        errors << "Critical Error found, no suppressions processed"
      else
        errors << "More than #{ALLOWABLE_ERRORS} found, no suppressions processed"
        return errors
      end
    else
      if errors.size > 0
        errors << "#{errors.size} non-critical errors found, #{processed_lines - errors.size} lines without errors were processed"
      end
      SuppressFinding.delete_all!(to_delete)
      SuppressFinding.create_all!(to_apply)
    end
    return errors
  end

  # validate the csv files first 500 rows
  def self.validate(section, file, group_name, scan_type, composit_org_id)

    errors =[]

    #
    # fetch the data might be needed for this request
    #
    group_id = group_name_to_id(section, composit_org_id, group_name)
    if group_id.nil?
      group_status = section == 'ooc' ? 'active' : 'current'
      return ["Group #{group_name} not found or is not #{group_status}"]
    end
    (findings, suppress_findings) = get_findings(section, composit_org_id, group_id, scan_type)
    suppressions = get_suppressions(composit_org_id)

    row_number = 0
    CSV.foreach("#{file}",{:headers=>false}) do |row|
      row_number += 1
      if row_number >= START_ROW and row.any? {|s| s.present?}
        # Pull out data from CSV row and convert
        finding_vid = row[11].to_s.to_i
        finding_hash = row[12].to_s.blank? ? nil : row[12].to_s
        finding_asset_id = row[13].to_s.to_i
        finding_suppression_name = row[5].to_s.blank? ? nil : row[5].to_s
        finding_validation_group = row[9].to_s.blank? ? nil : row[9].to_s

        # Verify data from CSV
        finding_id = validate_finding(findings, finding_vid, finding_hash, finding_asset_id)
        suppress_id = validate_suppression(suppressions, finding_suppression_name)

        # Look for errors
        if finding_vid == 0
          errors << "finding_vid is 0 or not a number in CSV file: line # #{row_number}"
        elsif finding_hash.nil?
          errors << "finding_hash is empty in CSV file: line # #{row_number}"
        elsif finding_asset_id == 0
          errors << "asset_id is 0 or not a number in CSV file: line # #{row_number}"
        elsif finding_id.nil?
          errors << "Unable to identify deviation in CSV file: line # #{row_number}, finding_vid, finding_hash or asset_id may have been altered"
        elsif suppress_id.nil? && !finding_suppression_name.blank?
          errors << "Suppression Name '#{finding_suppression_name}' not found or is expired: line # #{row_number}"
        else
          # no errors found
        end # if finding_vid == 0
        return errors if row_number > ALLOWABLE_ERRORS # after 500, stop processing.
      end # if row_number
    end # CSV.foreach
    return errors
  end

  def self.get_group_name(file)
    CSV.foreach(file,{:headers=>false}) do |row|
      if row[0]=~/^Group\:/
        size = row[0].size
        return row[0][7,size].strip
      end
    end
  end

  def self.get_scan_type(file)
    CSV.foreach(file,{:headers=>false}) do |row|
      if row[1]=~/^Scan Type\:/
        size = row[1].size
        return row[1][10,size].strip
      end
    end
  end
  private

  def self.validate_suppression(suppressions, name)
    return 0 if !name.nil? && name.downcase == REMOVE_SUPPRESSION_NAME
    s = suppressions[name]
    return s.nil? ? nil : s[:suppress_id]
  end

  def self.validate_finding(findings, finding_vid, finding_hash, asset_id)
    f = findings[finding_vid]
    return nil if f.nil?
    return f[:finding_id] if f.finding_vid == finding_vid && f.finding_hash == finding_hash && f.asset_id == asset_id
    return nil
  end

  #get devations for csv file
  def self.get_deviations(params,from_row,to_row)
    result=[]
    if params[:s]=='ic'
      result = DeviationSearch.search(params[:deviation_search],from_row,to_row)
      RAILS_DEFAULT_LOGGER.debug "SuppressionCSV: get_deviations: result.size: #{result.size}"
    elsif params[:s]== 'ooc'
      params[:deviation_search][:row_from]=from_row
      params[:deviation_search][:row_to]=to_row
      result = OocDeviationSearch.search(params[:deviation_search])
    end
    return result
  end

  def self.get_findings(section, composit_org_id, group_id, scan_type)

    create_temp_table
    populate_temp_table(section, group_id, scan_type)
    findings = get_findings_using_temp_table(composit_org_id)
    drop_temp_table

    finding_result = {}
    suppress_finding_result = Hash.new([])

    findings.each do |f|
      finding_result[f[:finding_vid]] = f
      unless f.suppress_id.nil?
        if suppress_finding_result.has_key?(f.finding_id)
          suppress_finding_result[f.finding_id] << f.suppress_id
        else
          suppress_finding_result[f.finding_id] = [f.suppress_id]
        end
      end
    end
    return [finding_result, suppress_finding_result]
  end

  def self.create_temp_table
    sql = "declare global temporary table #{TEMP_TABLE_NAME} as (
    select asset_id, scan_start_timestamp, tool_id
    from hip_scan_v as hs
    join dim_comm_tool_asset_scan_hist_v as s on s.scan_id = hs.scan_id
    ) DEFINITION ONLY with replace on commit preserve rows not logged"
    SwareBase.connection.execute(sql)
  end

  def self.drop_temp_table
    sql = "drop table session.#{TEMP_TABLE_NAME}"
    SwareBase.connection.execute(sql)
  end

  def self.populate_temp_table(section, group_id, scan_type)
    if section == 'ooc'
      sql = "with assets as (
      select ag.asset_id
      from hip_ooc_asset_group_v as ag
      join dim_comm_tool_asset_hist_v as a on a.tool_asset_id = ag.asset_id
      and current_timestamp between a.row_from_timestamp and coalesce(a.row_to_timestamp, current_timestamp)
      and system_status != 'decom'
      where ag.ooc_group_id = #{group_id}
      ),
      scans as (
      select s.asset_id, s.scan_start_timestamp, s.tool_id
      from hip_ooc_scan_v as s
      where s.asset_id in (select a.asset_id from assets as a)
      and s.ooc_group_id = #{group_id}
      and s.ooc_scan_type = #{SwareBase.quote_value(scan_type)}
      )	
      select count(*) from final table (
      insert into session.#{TEMP_TABLE_NAME} (asset_id, scan_start_timestamp, tool_id)
      (select asset_id, scan_start_timestamp, tool_id from scans)
      )"
    else
      sql = "with assets as (
      select ag.asset_id
      from hip_asset_group_v as ag
      join dim_comm_tool_asset_hist_v as a on a.tool_asset_id = ag.asset_id
      and #{SwareBase.quote_value(SwareBase.HcCycleAssetFreezeTimestamp)} between a.row_from_timestamp and coalesce(a.row_to_timestamp, current_timestamp)
      and system_status = 'prod'
      where ag.hc_group_id = #{group_id}
      ),
      scans as (
      select asset_id, scan_start_timestamp, tool_id
      from hip_scan_v as hs
      join dim_comm_tool_asset_scan_hist_v as s on s.scan_id = hs.scan_id
      where hs.period_id = #{SwareBase.current_period_id}
      and s.asset_id in (select a.asset_id from assets as a)
      )
      select count(*) from final table (
      insert into session.#{TEMP_TABLE_NAME} (asset_id, scan_start_timestamp, tool_id)
      (select asset_id, scan_start_timestamp, tool_id from scans)
      )"
    end
    return SwareBase.find_by_sql(sql)
  end

  def self.get_findings_using_temp_table(composit_org_id)
    sql = "select f.finding_vid, f.finding_id, f.asset_id, f.cat_name, f.finding_hash, v.sarm_cat_name, sfind.suppress_id
    from session.#{TEMP_TABLE_NAME} as s
    join fact_scan_v as f on f.asset_id = s.asset_id
    and (f.org_l1_id, f.org_id) = (#{composit_org_id})
    and f.scan_tool_id = s.tool_id
    and severity_id = 5
    and scan_service = 'health'
    and s.scan_start_timestamp between f.row_from_timestamp and coalesce(f.row_to_timestamp, current_timestamp)
    join dim_comm_vuln_v as v on v.vuln_id = f.vuln_id
    left join hip_suppress_finding_v as sfind on sfind.finding_id = f.finding_id"
    return SwareBase.find_by_sql(sql)
  end

  # get list of suppressions for account to validation file agains
  def self.get_suppressions(org_id)
    (l1id,id) = org_id.split(',')
    suppressions = Suppression.find(:all,:select=>"suppress_name,suppress_id",
    :conditions=>["org_l1_id=? and org_id=? and current_timestamp between start_timestamp and end_timestamp",l1id, id])
    result = {}
    suppressions.each do |s|
      result[s.suppress_name] = s
    end
    return result
  end

  def self.group_name_to_id(section, composit_org_id, group_name)
    (org_l1_id, org_id) = composit_org_id.split(',')
    if section == 'ooc'
      group = OocGroup.find(:first, :conditions => {:org_l1_id => org_l1_id,
        :org_id => org_id,
        :ooc_group_status => 'active',
        :ooc_group_name => group_name,
        })
    else
      group = HcGroup.find(:first, :conditions => {:org_l1_id => org_l1_id,
        :org_id => org_id,
        :is_current => 'y',
        :group_name => group_name,
        })
    end
    return group.nil? ? nil : group.id
  end

  def self.finding_suppress_match(suppress_findings, finding_id, suppress_id)
    if suppress_id.nil? && suppress_findings[finding_id].empty?
      return true
    else
      return suppress_findings[finding_id].include?(suppress_id)
    end
  end

  def self.already_processed?(processed, finding_id, suppress_id, action, row_number, errors)
    if processed.has_key?(finding_id)
      finding = processed[finding_id]
      if finding[:suppress_id] != suppress_id || finding[:action] != action
        errors << "Critical:  Row number #{row_number} is trying to process the same deviation as row number #{finding[:row_number]} but in a different way"
      end
      return true
    else
      processed[finding_id] = {:action => action, :row_number => row_number}
      return false
    end
  end

end
