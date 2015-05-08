class OutOfCycle::GroupsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:group_scan_lists]

  require_role "Deviation SME", :only=>["index,search"]
  require_role "GEO Focal" ,:only=>["index,search"]
  
  def index
    @show_element="outofcycle"
  end

  def search
    session[:per_page]=params[:per_page]
    session[:ooc_group_search] = 
      {:per_page => params[:per_page],
      'org_id'=>params[:org_id],
      'ooc_group_name'=>params[:ooc_group_name],
      'ooc_group_status'=>params[:ooc_group_status],
      'ooc_group_type'=>params[:ooc_group_type]
    }

    @groups = OocGroupSearch.search(params).paginate(:page=>params[:page],
      :per_page=>session[:ooc_group_search][:per_page])
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end
  
  def new
    @show_element="outofcycle"
    @group = OocGroup.new
  end

  def create
    @show_element="outofcycle"
    # Remove leading, trailing, and multiple blanks
    params[:ooc_group][:ooc_group_name] = params[:ooc_group][:ooc_group_name].strip.gsub(/\s{2,}/, ' ')
    
    @group = OocGroup.new(params[:ooc_group])
    @group.created_at=Time.now.utc
    @group.lu_userid=current_user.userid
    (org_l1,org_id) = current_org_id.split(',')
    @group.org_l1_id=org_l1
    @group.org_id=org_id

    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group Name was successfully created.'
        format.html { redirect_to(:action=>:index)}
      else
        flash[:error] = 'Group Name was not created.'
        format.html { render(:action=>"new")}
      end
    end

  end

  def edit
    @show_element="outofcycle"
    @group = OocGroup.find(params[:id])
  end

  def update
    @show_element="outofcycle"
    @group = OocGroup.find(params[:id])
    @group.lu_userid=current_user.userid

    # Remove leading, trailing, and multiple blanks
    params[:ooc_group][:ooc_group_name] = params[:ooc_group][:ooc_group_name].strip.gsub(/\s{2,}/, ' ')
    
    respond_to do |format|
      if @group.update_attributes(params[:ooc_group])
        flash[:notice] = 'Group Name was successfully updated.'
        format.html { redirect_to(:action=>"index") }
      else
        format.html { render :action => "edit" }
      end
    end
  end

end
