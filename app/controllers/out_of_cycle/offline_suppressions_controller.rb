class OutOfCycle::OfflineSuppressionsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:group_scan_lists,:get_file]

  def index
    @errors =[]
  end

  def search
    session[:per_page]=params[:per_page]
    session[:ooc_group_type] = params[:ooc_group_type]
    session[:ooc_group_id] = params[:ooc_group_id]
    session[:ooc_scan_type] = params[:ooc_scan_type]
    session[:ooc_deviation_search]=search_params(params)

    session[:ooc_deviation_search][:row_from]=0
    session[:ooc_deviation_search][:row_to]=1

    @params = params
#05-15-2013 
    if @params[:ooc_group_id].kind_of?(Array)
      group_id_list = @params[:ooc_group_id].map {|group_id| group_id.to_i}
    else
      group_id_list = @params[:ooc_group_id].to_i
    end

     @params[:group_names] = group_id_list

RAILS_DEFAULT_LOGGER.debug "OutOfCycle::OfflineSuppressionsController @params[:group_names] #{ @params[:group_names]}"

     result = OocDeviationSearch.search(session[:ooc_deviation_search])

 #debugger

#05-15-2013   count = result.first[:count] retuns Nil if no rows returned 
     count = result.first[:count]

 RAILS_DEFAULT_LOGGER.debug "OutOfCycle::OfflineSuppressionsController group_id_list #{group_id_list}"

     filename= "suppressions_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
     dir_name = "/reports/offline_suppression/#{current_org_id.sub(",","_")}"
     
 RAILS_DEFAULT_LOGGER.debug "OutOfCycle::OfflineSuppressionsController group_id_list #{group_id_list}"

# 05-16-213  original code    group_name = OocGroup.find([:ooc_deviation_search][:ooc_group_id].map {|group_id| group_id.to_i} ).ooc_group_name
# 05-16-2013 get the group_name for each group id
# 05-16-2013 and include it in each file  

    group_id_list.each do |select_group_id|

        group_name = OocDeviationSearch.findgroupname(select_group_id)

RAILS_DEFAULT_LOGGER.debug "group_name from find_groupname is #{group_name}"
 
    @count = count
    if count < APP['offline_suppression_background_count']
      create_csv_params = { :deviation_search=>session[:ooc_deviation_search],
        :filename=>filename,
        :dir_name=>dir_name,
        :s=>"ooc",
        :g=>group_name,
        :st=>session[:ooc_deviation_search][:ooc_scan_type]
      }
      OfflineSuppressions::SuppressionCsv.create_csv(create_csv_params)
      @filename="#{dir_name}/#{filename}"
    else
      @filename=nil
      qp="qp.#{Time.now.to_i}"
      file = File.new("#{RAILS_ROOT}/tmp/#{qp}","w+")
      file.puts session[:ooc_deviation_search].to_yaml
      file.close
      org = Org.find(current_org_id)
      TaskStatus.create({:instance_name=>'15minutes',
          :task_name=>"create_csv_#{current_org_id.sub(",","_")}_#{Time.now.to_i}",
          :class_name=>'OfflineSuppressions::DownloadSuppressionTask',
          :task_status=>'queued',
          :auto_retry=>'n',
          :task_message=>"Creating Suppressions CSV file for #{org.org_name}",
          :start_timestamp=>Time.now,
          :scheduled_timestamp=>Time.now,
          :lu_userid=>current_user.userid,
          :params=>{'qp'=>qp,
            'fn'=>filename,
            'u'=>current_user.userid,
            'org_id'=>current_org_id,
            'host'=>request.host_with_port,
            's'=>"ooc", # define which section we are using to determine which query to run. for now, ic (in cycle) or ooc (out of cycle)
            'g'=>group_name,
            'st'=>session[:ooc_deviation_search][:ooc_scan_type]
          }.to_json
        })
    end

   end  # end group_id_list.each  

    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end

  end


  def upload
    @show_element="outofcycle"
    @errors =[]
    @exception = false
    begin

      file = DataFile.save(params[:upload],APP['offline_suppression_files_path'])
      org = Org.find(current_org_id)

      group_name = OfflineSuppressions::SuppressionCsv.get_group_name(file)
      ooc_scan_type = OfflineSuppressions::SuppressionCsv.get_scan_type(file)
      if group_name.blank? or group_name.nil?
        @errors << "Group: value in file is missing or incorrect."
      end

      if ooc_scan_type.blank? or ooc_scan_type.nil?
        @errors << "Scan Type: value in file is missing or incorrect."
      end

      @errors << OfflineSuppressions::SuppressionCsv.validate('ooc',file,group_name,ooc_scan_type,current_org_id) if @errors.empty?
      @errors.flatten!
      @errors.compact!

      if @errors.empty?

        TaskStatus.create({:instance_name=>'15minutes',
          :task_name=>"upload_csv_#{current_org_id.sub(",","_")}_#{Time.now.to_i}",
          :task_status=>'queued',
          :class_name=>'OfflineSuppressions::UploadSuppressionTask',
          :auto_retry=>'n',
          :task_message=>"Importing Suppressions from CSV for #{org.org_name} ",
          :start_timestamp=>Time.now,
          :scheduled_timestamp=>Time.now,
          :lu_userid=>current_user.userid,
          :params=>{
            'fn'=>file.gsub(APP['offline_suppression_files_path'],""),
            'u'=>current_user.userid,
            'org_id'=>current_org_id,
            'host'=>request.host_with_port,
            'g'=>group_name,
            'st'=>ooc_scan_type,
            's'=>'ooc'
            }.to_json
          })
        @msg ="You will receive an email within 15 minutes providing status of your suppression upload."
      else
        File.unlink(file.to_s)
      end

    rescue Exception => e
      @exception = true

      RAILS_DEFAULT_LOGGER.error "Exception occured in offline suppression upload initial validation:  #{e.message}"
      RAILS_DEFAULT_LOGGER.error e.backtrace
    end

    @deviation_search = DeviationSearch.new
    render :action=>:index
  end

  def get_file
    storage_path = "#{RAILS_ROOT}/"
    send_file "#{storage_path}/#{params[:file]}",
      :type => 'text/csv; charset=iso-8859-1',
      :disposition => "attachment"
  end

   
  def search_params(params)
    {:per_page => params[:per_page],
      :org_id=>params[:org_id],
      :ooc_group_id=>params[:ooc_group_id],
      :ooc_scan_type=>params[:ooc_scan_type],
      :ooc_group_type=>params[:ooc_group_type],
      :host_name=>params[:host_name],
      :ip_address=>params[:ip_address],
      :os=>params[:os],
      :system_status=>params[:system_status],
      :val_group => params[:val_group],
      :vuln_title => params[:vuln_title],
      :vuln_text => params[:vuln_text],
      :deviation_level => params[:deviation_level],
      :val_status => params[:val_status],
      :suppress_id=>params[:suppress_id]
    }
  end
end
