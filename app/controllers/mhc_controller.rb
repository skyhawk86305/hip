class MhcController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:get]
  
  def index
    @errors = []
    
  end

  def upload
    @errors =[]
    #begin
    file = DataFile.save(params[:upload],APP["mhc_files_path"])
    org = Org.find(current_org_id)

    @errors = Mhc::MhcCsv.compact_flatten(Mhc::MhcCsv.validate_file({'org_id'=>current_org_id},file,APP['mhc_initial_check_count']))#validate the first x rows specificed in the config file

    if @errors.empty?
      TaskStatus.create({:instance_name=>'15minutes',
          :task_name=>"mhc_upload_#{current_org_id.sub(",","_")}_#{Time.now.to_i}",
          :task_status=>'queued',
          :class_name=>'Mhc::MhcTask',
          :auto_retry=>'n',
          :task_message=>"Upload MHC CSV for #{org.org_name} ",
          :start_timestamp=>Time.now,
          :scheduled_timestamp=>Time.now,
          :lu_userid=>current_user.userid,
          :params=>{
            'fn'=>file,
            'u'=>current_user.userid,
            'org_id'=>current_org_id
          }.to_json
        })
      @msg ="You will receive an email within 15 minutes providing status of your Manual Health Check."
    else
      File.unlink("#{file}")
    end


    #rescue Exception => e
    # @errors << e

    #end
    
    render :action=>:index
  end
end
