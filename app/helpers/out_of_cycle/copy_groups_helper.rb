module OutOfCycle::CopyGroupsHelper
  def action_text(code,ooc_group_type=nil,ooc_group_name=nil)
    case code
    when 'nothing'
      "System already exists in Target Group"
    when 'move'
     group = (ooc_group_type.nil? or ooc_group_name.nil?) ? "Source Group" : "(#{ooc_group_type}) #{ooc_group_name}"
      "Remove System from <b>#{group}</b>, Add System to <i>Target Group</i>"
    when 'move_other'
      "Remove System from <b>Other Groups</b>, Add System to <i>Target Group</i>"
    when 'delete'
      "Remove System From Target Group"
    when 'copy'
      "Add System to Target Group"
    end
  end

  def disabled_groups
    asset_freeze_timestamp = SwareBase.HcCycleAssetFreezeTimestamp
    beginning_of_month = Time.now.beginning_of_month
    if Time.now.between?(beginning_of_month,asset_freeze_timestamp)
      return all_groups_list.collect{|g| "#{g.group_id},#{g.group_type}" if g.group_type=="HC Cycle"}
    end
    return nil

  end
end
