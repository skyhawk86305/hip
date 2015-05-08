class OutOfCycle::AssetsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:group_scan_lists]

  require_role "Deviation SME", :only=>["index,search"]
  require_role "GEO Focal" ,:only=>["index,search"]

  def index
    @show_element="outofcycle"
  end

  # lookup from index page.
  def search
    session[:per_page]=params[:per_page]
    session[:ooc_group_type] = params[:ooc_group_type]
    session[:ooc_group_id] = params[:ooc_group_id]
    session[:ooc_asset_search] = asset_params(params)
    @assets = OocAssetSearch.search(session[:ooc_asset_search]).paginate :page=>params[:page],
      :per_page=>session[:ooc_asset_search][:per_page]
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end


  def update
    option= params[:option]
    group = OocGroup.find(params[:select_ooc_group_id]) unless params[:select_ooc_group_id].blank?
    total_systems=0
   
    case option
    when "selected"
      total_systems =  apply_update(params[:assets].values)
    when "all"
      total_systems = apply_update(OocAssetSearch.search(session[:ooc_asset_search]))
    end
    
    SwareBase.uncached do
      @assets = OocAssetSearch.search(session[:ooc_asset_search]).paginate :page=>params[:page],
        :per_page=>session[:ooc_asset_search][:per_page]
    end

    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
          page << "systemsExceeded('#{group.ooc_group_name}','#{total_systems}')" if total_systems >= 200
        end
      }
    end

  end

  private

  def apply_update(assets)
    ooc_group=params[:select_ooc_group_id].to_i
    total_systems=0
    new_assets=[]
    scans = []
    asset_group=nil
    asset_groups=nil
    unless ooc_group==0
      # need to keep getting the group, they
      # may not be in order.
      group = OocGroup.find(ooc_group)
      # keep count of system
      # as we add systems to the group
      total_systems = OocAssetGroup.production.find(:all, :conditions => {:ooc_group_id => group.id}).size
    end
    unless session[:ooc_asset_search][:ooc_group_id].blank?
      # is the following querey correct when ooc_group_id is either "assigned" or "unassigned"?
      source_ooc_group_id = session[:ooc_asset_search][:ooc_group_id]
      if source_ooc_group_id == 'unassigned'
        asset_groups = []
      elsif source_ooc_group_id == 'assigned'
        (org_l1_id,org_id) = current_org_id.split(',')
        groups = OocGroup.find(:all, :conditions => {:org_l1_id => org_l1_id, :org_id => org_id, :ooc_group_status => "active", :ooc_group_type => session[:ooc_group_type]})
        asset_groups = groups.inject([]) {|asset_groups, group| asset_groups += group.ooc_asset_groups}
      else
        asset_groups = OocAssetGroup.find(:all,:conditions=>["ooc_group_id=?", source_ooc_group_id.to_i]) # search is wrong for "all assigned"
      end
      # CORRECT: If we corrected the above search to account for "all assigned" and "all not assigned"  
      OocAssetGroup.transaction do
        assets.each do |a|
          #if there is not a group id- then that is unassigned,
          #and there can be unlimited unassigned systems
          asset_id = (a['selected'].blank? or a['selected']=='n') ? a['tool_asset_id']: a['selected']
          unless asset_id.blank?
            if (total_systems < 200)
              asset_group = asset_groups.find{|ag| 
                ag['asset_id'].to_i==asset_id.to_i# and
                #ag['ooc_group_id'].to_i==a['ooc_group_id'].to_i 
              }  unless asset_groups.nil? 
              if !asset_group.nil? and asset_group.ooc_group_id.to_i!=ooc_group and ooc_group!=0
                asset_group.delete
                new_assets << {
                  :asset_id=>asset_id,
                  :ooc_group_id=>ooc_group,
                  :lu_userid=>current_user.userid
                } 
                scans << {
                  :ooc_group_id=>ooc_group,
                  :asset_id=>asset_id,
                  :org_ooc_group_id=>a['ooc_group_id']
                }
              elsif asset_group.nil? and ooc_group!=0
                new_assets << {
                  :asset_id=>asset_id,
                  :ooc_group_id=>ooc_group,
                  :lu_userid=>current_user.userid
                }
                scans << {
                  :ooc_group_id=>ooc_group,
                  :asset_id=>asset_id,
                  :org_ooc_group_id=>a['ooc_group_id']
                }
              elsif !asset_group.nil? and ooc_group==0
                asset_group.delete
                scans << {
                  :ooc_group_id=>ooc_group,
                  :asset_id=>asset_id,
                  :org_ooc_group_id=>a['ooc_group_id']
                }
                total_systems =0 # reset total_system, there is no limit on unassigned systems
              end
              total_systems +=1
            else      
              update_scans(scans)
              OocAssetGroup.create_all!(new_assets)
              return total_systems
            end
          end
        end
      end
        update_scans(scans)
        OocAssetGroup.create_all!(new_assets)
      end
      return total_systems
    end
 
    def asset_params(params)
      {:per_page => params[:per_page],
        :org_id=>params[:org_id],
        :ooc_group_id=>params[:ooc_group_id],
        :ooc_group_status=>params[:ooc_group_status],
        :ooc_group_type=>params[:ooc_group_type],
        :host_name=>params[:host_name],
        :ip_string_list=>params[:ip_string_list],
        :os_product=>params[:os_product],
        :hc_required=>params[:hc_required],
        :hc_sec_class=>params[:hc_sec_class],
        :system_status=>params[:system_status]
      }
    end
  
    def update_scans(scans)
      scan=nil
      # a scan may exist and if it does change the group
      scans.each do |params|
        if !params[:asset_id].blank? and params[:ooc_group_id]!=0
          scan=OocScan.find_by_asset_id_and_ooc_group_id(params[:asset_id].to_i,params[:org_ooc_group_id].to_i)
          unless scan.nil?
            attributes={:ooc_group_id=>params[:ooc_group_id]}
            scan.update_attributes(attributes)
          end
        end
    
        #remove existing scan if the asset is changed to unassigned
        if  !params[:asset_id].blank? and params[:ooc_group_id]==0
          # can only unlabel scans that are not released.
          scan = OocScan.find_by_asset_id(params[:asset_id])#,:conditions=>"publish_ready_timestamp is null")
          scan.destroy unless scan.nil?
        end
      end
    end
  
end

