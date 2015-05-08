class ReportsController < ApplicationController

  before_filter :select_org
  before_filter :has_current_org_id

  def index
  end

end
