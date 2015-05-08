class MaintainFindingCache < ScheduledTask
  
  def self.get_task_objects(config,queued_tasks = [])
    @@config = config
    return [self.new('MaintainDeviationCache', Time.now.utc, 'n', nil)]
  end
  
  attr_reader :name, :last_run_timestamp, :auto_retry, :queued_task_id
  
  def initialize(name, last_run_timestamp, auto_retry, queued_task_id)
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
    @queued_task_id = queued_task_id
  end
  
  def run()
    FindingCacheSet.invalidate_cache_on_hipmart_update
    FindingCacheSet.invalidate_old_cache_sets
    {:success => true}
  end
  
end