class AutoRelease < ScheduledTask
  
  def self.get_task_objects(config,queued_tasks = [])
    @@config = config
    # TODO get schedule time from period table (new column)
    return [self.new('AutoRelease', Time.now.utc, 'y',nil)]
  end
  
  attr_reader :name, :last_run_timestamp, :auto_retry,:queued_task_id
  
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id)
  end
  
  def run()
    override_date = @@config[:override_date]
    SwareBase.set_period(override_date) if override_date
        
    # TODO:  Put application into read only mode
    
    # Get groups active HC Cycle groups from orgs subscribed to HIP
    groups = HcGroup.find_all_current_groups
    
    groups.each do |group|
      # Output a status message in case anyone is watching
      puts "Processing Org \"#{Org.find([group.org_l1_id, group.org_id]).org_name}\", group \"#{group.group_name}\""
      # Get the unreleased scans for this group
      scans = PublishScanSearch.search('hc_group_id' => group.hc_group_id.to_s,
        'org_id' => "#{group.org_l1_id},#{group.org_id}",
        'os' => 'all', 'scan_type' => 'all')
      # Extract the scan_ids
      scan_ids = scans.map{|scan| scan.scan_id}
      # Release all the scans
      Scan.create_all!(scan_ids, SwareBase.username, SwareBase.current_period_id)
    end
      
    # TODO: Run month end reports
    
    # TODO: Take application out of read only mode
    
    SwareBase.reset_period if override_date
    {:success => true}
  end
  
end