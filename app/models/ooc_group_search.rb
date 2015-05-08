class OocGroupSearch
  
  #
  # Disable calls to new from outside the class
  #
  #private_class_method :new
  
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
  
  #########
  private
  #########
  
  def initialize(params)
    @params = params
  end
  
  def org_l1_id
    @params['org_id'].split(',')[0]
  end
  
  def org_id
    @params['org_id'].split(',')[1]
  end
  
  def sql
    "SELECT * FROM hip_ooc_group_v WHERE
      #{conditions}
      AND ooc_group_status !='deleted'
      ORDER BY ooc_group_name
    "
  end

  def org_conditions
    ["org_l1_id=#{org_l1_id} and org_id=#{org_id}",nil]
  end

  def group_name_conditions
    ["lower(ooc_group_name) like '%#{@params[:ooc_group_name].downcase.strip}%'",nil] unless @params[:ooc_group_name].blank?
  end

  def group_status_conditions
    ["ooc_group_status = '#{@params[:ooc_group_status]}'",nil] unless @params[:ooc_group_status].blank?
  end
  def group_type_conditions
    ["ooc_group_type = '#{@params[:ooc_group_type]}'",nil] unless @params[:ooc_group_type].blank?
  end

  def conditions
    [conditions_clauses.join(' AND '), *conditions_options].join('') unless conditions_options.blank?
  end

  def conditions_clauses
    conditions_parts.map { |condition| condition.first }
  end

  def conditions_options
    conditions_parts.map { |condition| condition[1..-1] }.flatten
  end

  def conditions_parts
    self.private_methods.grep(/_conditions$/).map { |m| send(m) }.compact
  end
end
