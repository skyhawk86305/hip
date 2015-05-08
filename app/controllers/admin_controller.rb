class AdminController < ApplicationController
  require_role 'Admin'


  def index
  end

end
