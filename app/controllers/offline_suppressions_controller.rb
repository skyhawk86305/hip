class OfflineSuppressionsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:get_file]

  def index
    @show_element="incycle"
    @deviation_search = DeviationSearch.new
    @errors =[]
  end

  def search
debugger
    session[:hc_group_id]=params[:deviation_search][:hc_group_id]
    session[:deviation_search]=params[:deviation_search]

    result = DeviationSearch.search(params[:deviation_search], 0, 1)
    count = result.size == 0 ? 0 : result.first.count
    filename= "suppressions_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
    dir_name = "/reports/offline_suppression/#{current_org_id.sub(",","_")}"
    group_name = HcGroup.find(session[:deviation_search][:hc_group_id]).group_name
    @count = count
    if count < APP['offline_suppression_background_count']
      create_csv_params = { :deviation_search=>params[:deviation_search],
        :filename=>filename,
        :dir_name=>dir_name,
        :s=>"ic",
        :g => group_name
      }
      SuppressionCsv.create_csv(create_csv_params)
      @filename="#{dir_name}/#{filename}"
    else
      @filename=nil
      qp="qp.#{Time.now.to_i}"
      file = File.new("#{RAILS_ROOT}/tmp/#{qp}","w+")
      file.puts session[:deviation_search].to_yaml
      file.close
      org = Org.find(current_org_id)
      TaskStatus.create({:instance_name=>'15minutes',
          :task_name=>"create_csv_#{current_org_id.sub(",","_")}_#{Time.now.to_i}",
          :class_name=>'DownloadSuppressionTask',
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
            's'=>"ic", # define which section we are using to determine which query to run. for now, ic (in cycle) or ooc (out of cycle)
            'g'=>group_name,
            'st'=>nil,
          }.to_json
        })
    end

    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end

  def upload
    @show_element="incycle"
    @errors =[]
    @exception = false
    begin
      
      file = DataFile.save(params[:upload],APP['offline_suppression_files_path'])
      org = Org.find(current_org_id)
      
      group_name = SuppressionCsv.get_group_name("#{file}")
      if group_name.blank? or group_name.nil?
        @errors << "Group: value in file is missing or incorrect."
      end
      
      @errors << SuppressionCsv.validate('ic',file,group_name,nil,current_org_id) if @errors.empty?
      @errors.flatten!
      @errors.compact!
      
      if @errors.empty?

        TaskStatus.create({:instance_name=>'15minutes',
            :task_name=>"upload_csv_#{current_org_id.sub(",","_")}_#{Time.now.to_i}",
            :task_status=>'queued',
            :class_name=>'UploadSuppressionTask',
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
              's'=>'ic',
              'st'=>nil
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
end
