class Admin::HipConfigsController < ApplicationController
  require_role 'Admin'
  def index
    @configs = HipConfig.all(:order=>:key)
    @config = HipConfig.new
  end

  def create
    config = HipConfig.new(params[:hip_config])
    config.lu_userid=current_user.userid
    respond_to do |format|
      if config.save
        AppConfig.fetch_config_options #load the new config
        flash[:notice] = 'Config was successfully updated.'
        format.html {redirect_to :action=>:index }
      else
        @configs = HipConfig.all(:order=>:key)
        @config = HipConfig.new
        flash[:notice] ="There was a problem updating this record."
        format.html { render :action => "index"}
      end
    end
  end

  def update
    HipConfig.transaction do
      params[:config].values.each do |config|
        params = {:key=>config['key'],
          :value=>config['value'],
          :lu_userid=>current_user.userid,
        }
        begin
          @config = HipConfig.find(config['id'])
          @config.update_attributes!(params)
          AppConfig.fetch_config_options #load the new config
        rescue
          #end the error and validation messages
          flash[:notice] ="There was a problem updating this record."
          @configs = HipConfig.all(:order=>:key)
          @config = HipConfig.new
          render :action => "index"
          return
        end

      end

    end
    flash[:notice] = 'Config was successfully updated.'
    redirect_to(:action=>"index" )
    return
  end

  def reload_config
    c=AppConfig.new
    flash[:notice] = "Config has been reloaded."
    redirect_to :action=>:index
  end

  def destroy
    @config = HipConfig.find(params[:id])
    @config.destroy
    respond_to do |format|
      format.html { redirect_to(admin_hip_configs_path) }

    end
  end
end
