module ScansHelper
  
  # do not allow users to change the select list if
  # the publish_ready_timestamp has been set
  def disable_select(scan_id)
    if scan_id.blank?
      return false
    end
    scan=Scan.find scan_id
    scan.publish_ready_timestamp.blank? ?false:true
  end

  def remove_label_link(scan_id,row, page)
    if ! scan_id.blank?
      scan=Scan.find scan_id
    end
    if scan_id.blank? or (!scan.blank? and scan.publish_ready_timestamp.blank? )
      if hide_element
        return "remove label"
      else
        return link_to_remote("remove label",
                              :url=>{:controller=>:scans,
                                     :action=>:update,
                                     :option=>"remove_label",
                                     :scan_id=>scan.scan_id,
                                     :page => page,
                                     :row=>row},
                              :method => :delete,
        :confirm=>"Are you sure you want to remove this scan label?")
      end
      
    end
    
  end

  # lookup missing scans reason from asset_id
  # need to lookup period_id, then get the missed_scan_id to then
  # retreive the reason
  def get_missed_scan_reason(asset_id)
    period = HipPeriod.current_period.first
    id = MissedScan.find(:first,:conditions=>{:asset_id=>asset_id,:period_id=>period.period_id}).missed_scan_reason_id
    if !id.nil?
      return MissedScanReason.find(id).missed_scan_reason
    end
    #if missed scan has not been set
    "Not Specified Yet"
  end
end
