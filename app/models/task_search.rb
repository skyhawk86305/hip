class TaskSearch

 
  private_class_method :new
  
  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end

  def self.search(params)
    search_params = new(params)
    search_params.search
  end
  
  def search
    result = SwareBase.find_by_sql(sql)
    return result
  end

  private
  def initialize(params)
    @params = params
  end
  # query for paination for review
  def sql
    "select * from hip_task_status_v 
   #{"WHERE " unless conditions.nil?}
   #{conditions}
   order by scheduled_timestamp desc"
  end
 
  def instance_name_conditions
    ["instance_name = '#{@params[:instance_name]}'",nil] unless @params[:instance_name].blank?
  end
  def task_status_conditions
    ["task_status = '#{@params[:task_status]}'",nil] unless @params[:task_status].blank?
  end
  def auto_retry_conditions
    ["auto_retry = '#{@params[:auto_retry]}'"] unless @params[:auto_retry].blank?
  end
  def task_name_conditions
    ["lower(task_name) like '%#{@params[:task_name].downcase.strip}%'",nil] unless @params[:task_name].blank?
  end

  def task_message_conditions
    ["lower(task_message) like '%#{@params[:task_message].downcase.strip}%'",nil] unless @params[:task_message].blank?
  end

  def class_name_conditions
    ["lower(class_name) like '%#{@params[:class_name].downcase.strip}%'",nil] unless @params[:class_name].blank?
  end
  def params_conditions
    ["lower(params) like '%#{@params[:params].downcase.strip}%'",nil] unless @params[:params].blank?
  end

  def scheduled_conditions
    ["scheduled_timestamp between '#{@params[:start_scheduled_timestamp]}' and '#{@params[:end_scheduled_timestamp]}'",nil] unless @params[:start_scheduled_timestamp].blank? and @params[:end_scheduled_timestamp].blank?
  end
  
  def started_conditions
    ["start_timestamp between '#{@params[:start_timestamp]}' and '#{@params[:end_timestamp]}'",nil] unless @params[:start_timestamp].blank? and @params[:end_timestamp].blank?
  end
  
  def conditions
    [conditions_clauses.join(' AND '), *conditions_options].join('') unless conditions_options.blank?
  end

  def conditions_clauses
    conditions_parts.map { |condition|  condition.first }
  end

  def conditions_options

    conditions_parts.map { |condition| condition[1..-1] }.flatten
  end

  def conditions_parts
    self.private_methods.grep(/_conditions$/).map { |m| send(m) }.compact
  end
end
