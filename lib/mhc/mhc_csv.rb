class Mhc::MhcCsv

  # create the csv file for download
  def self.create_etl_file(params,task_id)
    org = Org.find(params['org_id'])
    org_ecm_account_id = org.org_ecm_account_id
    org_name = org.org_name

    state="writing"
    filename="#{APP['mhc_files_path']}/scan_std_ver-3_bid-#{task_id}_eetime-#{Time.now.strftime("%Y%m%d%H%M%S")}_state-#{state}.dat"

    row_num=1
    errors=[]
    CSV.open(filename,'w',{:force_quotes => true}) do |csv|
      csv << ["chip account id", 
        "account name", 
        "account type", 
        "scan_id", 
        "scan start timestamp" ,
        "scan stop timestamp",
        "scan service", 
        "scan tool",
        "finalization status", 
        "finalization timestamp",
        "finalization userid ",
        "scanner hostname", 
        "scan parameters", 
        "recommendations ",
        "host_id ",
        "hostid type ",
        "host ip string" ,
        "host name" ,
        "host scan start timestamp ",
        "host scan stop timestamp", 
        "host status",
        "os name",
        "host scan status",
        "policy name ",
        "policy type ",
        "policy version ",
        "port ",
        "protocol ",
        "service ",
        "score code",
        "age ",
        "standard finding desc",
        "actual finding_text", 
        "policy_category_major",
        "policy_category_minor", 
        "suppression_status", 
        "suppression_reason", 
        "suppression_ref"
        ] # csv headers
      validate = ValidateForOrg.new(params['org_id'])

      # Count the number of rows per host so that we can componsate for any scans with no rows after
      # the Compliant rows are eliminated
      host_row_sent_count = {}
      host_policy_name = {} #  We'll save the policy name for the dummy record in this hash

      CSV.foreach("#{params['fn']}") do |row|
        if row_num >= 3
          row[1] = row[1].strip unless row[1].nil?
          
          row_errors = compact_flatten(validate_row(validate,row,row_num))

          host_row_sent_count[row[3]] = 0 if !row[3].nil? && host_row_sent_count[row[3]].nil?
          host_policy_name[row[3]] = row[5] if !row[3].nil? && host_policy_name[row[3]].nil?

          # when the upload csv file has errors, do not add it to the file
          if row_errors.size == 0 && !empty_row?(row)
            time_string = validate.to_timestamp(row[9]).strftime("%Y-%m-%d-%H.%M.%S")
            host_row_sent_count[row[3]] += 1
            csv << [
              row[1],#chip account id 
              row[2], # account name 
              'chip',#account type 
              'unk',#scan_id 
              time_string,#scan start timestamp 
              time_string,# scan stop timestamp  where do I get STOP_SCAN_TIMESTAMP ??
              'health',#scan service 
              validate.to_scan_tool(row[4]),#scan tool 
              'complete',#finalization status 
              time_string,#finalization timestamp
              'unk',#finalization userid 
              'unk',#scanner hostname 
              'unk',#scan parameters 
              'unk',#recommendations 
              'unk',#host_id 
              'unk',#host_id type 
              'unk',#host ip string 
              row[3],#host name 
              time_string,#host scan start timestamp 
              time_string,#host scan stop timestamp 
              'up',#host status how to tell if up/down ???
              'unk',#os name  how to get ??? 
              'unk',#host scan status ???
              row[5],#policy name 
              'unk',#policy type 
              'unk',#policy version 
              'unk',#port 
              'unk',#protocol 
              'unk',#service 
              validate.transform_deviation_level(row[11]),
              '',#age 
              String(row[6])[0..254],#standard finding desc
              row[12][0..700],#actual finding_text 
              'unk',#policy_category_major
              'unk',#policy_category_minor 
              'n',#suppression_status 
              'unk',#suppression_reason 
              'unk',#suppression_ref 
              #row[13],#deviation category
            ]
          end
          errors << row_errors
        end
        row_num += 1
      end

      RAILS_DEFAULT_LOGGER.debug "host_row_sent_count: #{host_row_sent_count.inspect}"
      # Write out dummy records for clean scans
      if errors.empty?  # if there have been errors, there's not point in processing clean scans
        host_row_sent_count.each do |host_name, count|
          scan_timestamp = validate.get_scan_timestamp(host_name).strftime("%Y-%m-%d-%H.%M.%S")
          if count == 0
            csv << [
                org_ecm_account_id.strip,#chip account id 
                org_name, # account name 
                'chip',#account type 
                'unk',#scan_id 
                scan_timestamp,#scan start timestamp 
                scan_timestamp,#scan stop timestamp
                'health',#scan service 
                validate.get_scan_tool_name(host_name),#scan tool 
                'complete',#finalization status 
                scan_timestamp,#finalization timestamp
                'unk',#finalization userid 
                'unk',#scanner hostname 
                'unk',#scan parameters 
                'unk',#recommendations 
                'unk',#host_id 
                'unk',#host_id type 
                'unk',#host ip string 
                host_name,#host name 
                scan_timestamp,#host scan start timestamp 
                scan_timestamp,#host scan stop timestamp 
                'up',#host status how to tell if up/down ???
                'unk',#os name  how to get ??? 
                'unk',#host scan status ???
                host_policy_name[host_name],#policy name 
                'unk',#policy type 
                'unk',#policy version 
                'unk',#port 
                'unk',#protocol 
                'unk',#service 
                "info",
                '',#age 
                "SCAN SUCCESSFUL (GTL)",#standard finding desc
                "SCAN SUCCESSFUL (GTL)",#actual finding_text 
                'unk',#policy_category_major
                'unk',#policy_category_minor 
                'n',#suppression_status 
                'unk',#suppression_reason 
                'unk',#suppression_ref 
                #row[13],#deviation category
              ]
          end
        end
      end

    end

    errors = compact_flatten(errors)
    # Only create the gzip file if there are no errors.  If there are errors, the gzip file will not be created, and the ETL processing
    # Will not pick it up.
    if errors.empty?
      old_filename=filename
      #gzip the file
      gz = Zlib::GzipWriter.open("#{old_filename}.gz")
      gz.write IO.read(old_filename)
      gz.close
      #rename the file now that it's complete
      state="written"
      new_filename="#{APP['mhc_files_path']}/scan_std_ver-3_bid-#{task_id}_eetime-#{Time.now.strftime("%Y%m%d%H%M%S")}_state-#{state}.dat.gz"
      File.rename("#{old_filename}.gz",new_filename)
      File.chmod(0664, new_filename)
      File.unlink(old_filename)
    end

    return errors
  end

  # validate the csv file 
  def self.validate_file(params,file,rows=0)
    row_num=1
    errors =[]
    error_threshold = APP['mhc_error_threshold']
    validate = ValidateForOrg.new(params['org_id'])
    CSV.foreach("#{file}",{:headers=>false}) do |row|
      if row_num >= 3

        row[1] = row[1].strip unless row[1].nil?
        errors << validate_row(validate,row,row_num)
        if rows!=0 and row_num == rows
          return errors # stop processing after requested number of rows
        end
      end

      if errors.size==error_threshold
        return errors
      end
      row_num +=1
    end

    return errors
  end

  #validate the row
  def self.validate_row(validator,row,row_num)
    errors=[]
    # skip empty rows
    return errors if empty_row?(row)
    # test for column count
    errors << validate_column_num(row)
    # test chip id
    errors << validator.chip_id(row[1])
    # test syntax/values
    errors << validator.string("Template Version",row[0],false)
    errors << validator.int("Account Chipid",row[1],false) # probably shouldn't fail
    errors << validator.string("Account Name",row[2],true) # just passed on to ETL, not validated
    errors << validator.host_name("System Name",row[3],false)
    errors << validator.tool_name("Scan Method",row[4],false, row[3])
    errors << validator.string("Base Security Policy/Version",row[5],false)
    errors << validator.string("System Check / Parameter",row[6],true)
    errors << validator.string("Required / Agreed To Value",row[7],true)
    errors << validator.scan_timestamp("Date Actual Values Documented",row[9],false, row[3])
    errors << validator.string("File Submitted By",row[10],false)
    errors << validator.deviation_level("Deviation Level",row[11],false)
    errors << validator.string("Finding Text",row[12],false)
    return compact_flatten(errors).map {|e| "#{e}: line # #{row_num}"}
  end

  #compact and flatten the array for easier use later.
  def self.compact_flatten(array)
    array.flatten!
    array.compact!
    return array
  end

  def self.validate_column_num(row)
    #validate number of columns for row
    errors=[]
    unless row.size==13
      errors =  "Incorrect number of columns found"
    end
    return errors
  end
   
  def self.empty_row?(row)
    (row.find() {|cell| !cell.to_s.blank?}).nil?
  end

end