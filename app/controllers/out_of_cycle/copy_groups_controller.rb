class OutOfCycle::CopyGroupsController < ApplicationController

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
    session[:ooc_copy_groups_search] = {
      :group_src=>params[:group_src],
      :group_target=>params[:group_target],
      :org_id=>current_org_id,
      :per_page=>params[:per_page]
    }
    unless params[:group_src].split(',')[1] == 'HC Cycle'
      @group_src_name = OocGroup.find(params[:group_src].split(',')[0]).ooc_group_name
    else
      @group_src_name = HcGroup.find(params[:group_src].split(',')[0]).group_name
    end

    assets = OocCopyGroupsSearch.search(session[:ooc_copy_groups_search])
    @assets = assets.paginate :page=>params[:page],
      :per_page=>session[:ooc_copy_groups_search][:per_page]

    @total_copy = assets.find_all{|a| a.action_code=='copy'}.size
    @total_move = assets.find_all{|a| a.action_code=='move' and a.ooc_group_name == @group_src_name}.size
    @total_move_other = assets.find_all{|a| a.action_code=='move' and  a.ooc_group_name != @group_src_name}.size
    @total = @total_copy + @total_move
    @total_error = assets.find_all{|a| a.action_code=='error'}.size
    @total_nothing = assets.find_all{|a| a.action_code=='nothing'}.size
    @total_deleted = assets.find_all{|a| a.action_code=='delete'}.size

    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end

  def update
    @assets = OocCopyGroupsSearch.search(session[:ooc_copy_groups_search])
    group_target_id=params[:group_target]
    @count = 0 # get a total count copied.
    @assets.each do |asset|

      OocAssetGroup.transaction do
        case asset['action_code']
        when "copy"
          # the asset is in the source group, and not in the target
          # group or another group of the same group type.
          new_asset_group(asset['asset_id'],group_target_id)
          @count +=1
        when "move"
          # remove the asset from the other group
          # add it to the new group.
          # assets can not exist in two groups of the same group type
          ag = OocAssetGroup.find([asset['ooc_group_id'],asset['asset_id']])
          ag.destroy
          new_asset_group(asset['asset_id'],group_target_id)
          @count +=1
        when "delete"
          # there is no source asset_id, but there is a target asset_id.  remove
          # the asset from the target group, so the two groups match.
          ag = OocAssetGroup.find([asset['ooc_group_id'],asset['asset_id']])
          ag.destroy
        end
      end
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", "<hr/><p>The copy was successful!  <b>#{@count} systems copied</b>.</p>")

        end
      }
    end
  end

  private
  def new_asset_group(asset_id,group_id)
    OocAssetGroup.create(:asset_id=>asset_id,:ooc_group_id=>group_id,:lu_userid=>current_user.userid)
  end
end
