class AssetsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search]

  require_role "Deviation SME", :only=>["index,search"]
  require_role "GEO Focal" ,:only=>["index,search"]
  def index

    @show_element="incycle"
    @asset = AssetSearch.new
    # set default for query page
    @hc_group_id='unassigned'
  end

  def autocomplete_lookup
    query=params[:query]
    @org = Org.find(current_org_id)
    @assets = @org.assets.find(:all,:conditions=>['lower(host_name) LIKE ?', "%#{query.downcase}%"])
    respond_to do |format|
      format.html {render :layout => false}
      format.js { render :layout => false }
    end
  end
  # lookup from index page.
  def search
    session[:hc_group_id]=params[:asset_search][:hc_group_id]
    session[:per_page]=params[:asset_search][:per_page]
    @assets = AssetSearch.assets(params[:asset_search]).paginate :page=>params[:page],
      :per_page=>params[:asset_search][:per_page]
    session[:asset_search]=params[:asset_search]
  end


  def update
    option= params[:option]
    total_systems=0
    group = HcGroup.find(params[:hc_group]) unless params[:hc_group].blank?
    case option
    when "selected"
      total_systems=apply_update(params[:assets].values)
    when "all"
      total_systems=apply_update(AssetSearch.assets(session[:asset_search]))
    end

    @assets = AssetSearch.assets(session[:asset_search]).paginate :page=>params[:page],
      :per_page=>session[:asset_search][:per_page]

    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
          page << "systemsExceeded('#{group.group_name}','#{total_systems}')" if total_systems > 200
        end
      }
    end

  end

  private

  def apply_update(assets)
    hc_group_id=params[:hc_group].to_i
    asset_groups = nil
    ag = nil
    new_assets =[]
    unless hc_group_id==0
      # keep count of system
      # as we add systems to the group
      group = HcGroup.find hc_group_id 
      total_systems = group.asset_groups.production.size
    else
      total_systems=0
    end

    asset_ids = assets.map do |a|
      (a['selected'].blank? or a['selected']=='n') ? a['tool_asset_id']: a['selected']
    end
    asset_groups = AssetGroup.find(:all, :conditions => ["asset_id in (?)", asset_ids])
    assets.each do |a|
      #if there is not a group id- then that is unassigned,
      #and there can be unlimited unassigned systems
      asset_id = (a['selected'].blank? or a['selected']=='n') ? a['tool_asset_id']: a['selected']

      unless  asset_id.blank?
        # get asset group for asset so we can compare existing group and new group
        if (total_systems < 200)
          asset_group = asset_groups.find{|ag| ag['asset_id'].to_i==asset_id.to_i} unless asset_groups.nil?

          if !asset_group.nil? and asset_group.hc_group_id.to_i!=hc_group_id and hc_group_id!=0
            asset_group.delete
            new_assets<<{
              :asset_id=>asset_id,
              :hc_group_id=>hc_group_id,
              :lu_userid=>current_user.userid
            }
          elsif asset_group.nil? and hc_group_id!=0
            new_assets<<{
              :asset_id=>asset_id,
              :hc_group_id=>hc_group_id,
              :lu_userid=>current_user.userid
            }
          elsif !asset_group.nil? and hc_group_id==0
            asset_group.delete
            total_systems =0
          end
          total_systems +=1
        else
          AssetGroup.create_all!(new_assets)
          return total_systems
        end
      end
    end            
    AssetGroup.create_all!(new_assets)

    return total_systems
  end

end
