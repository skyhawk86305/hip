class VulnsController < ApplicationController

  def index
    title=params[:title]
    @vulns = Vuln.find(:all,:conditions=>['lower(title) LIKE ?', "%#{title.downcase}%"])
    respond_to do |format|
      format.html { render :layout => false }
      format.js { render :layout => false }
    end
  end
end
