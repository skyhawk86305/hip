class Admin::OrgsController < ApplicationController

  def index
    org_name=params[:org_name]
    @orgs = Org.service_hip.find(:all,:conditions=>['lower(org_name) LIKE ?', "%#{org_name.downcase}%"])
    respond_to do |format|
      format.html
      format.js { render :layout => false }
      #format.js do
        #render :inline => "<%= auto_complete_result(@orgs, 'org_name') %>"
      #end
    end
  end

end
