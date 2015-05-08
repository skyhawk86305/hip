class ExceptionSearch

  attr_accessor :hc_group_id, :suppress_name,:asset_id,:approval_status,:suppress_class,:automatic_suppress_flag,:vuln_id,
    :page,:per_page,:sort,:vuln_title,:host_name
  
  # Since this isn't a real ActiveRecord object, we'll fake an ID for it:
  def id
    nil
  end

  # query for a list of assets
  def self.exceptions(params,page)
    @hc_group_id=params['hc_group_id']
    @suppress_name=params['suppress_name']
    @asset_id=params['asset_id']
    @approval_status=params['approval_status']
    @suppress_class=params['suppress_class']
    @automatic_suppress_flag = params['automatic_suppress_flag']
    @vuln_id = params['vuln_id']
    @org_id=params['org_id']
    @page=page
    @per_page=params['per_page']
    @sort=params['sort']
    find_exceptions
  end

 
  def per_page=(per_page)
    @per_page=per_page
  end

  def per_page
    @per_page
  end


  def sort=(sort)
    @sort=sort
  end
  
  def sort
    @sort
  end

  def page(page)
    @page=page
  end

  def page
    @page
  end
  def hc_group_id
    @hc_group_id
  end

  def hc_group_id=(hc_group_id)
    @hc_group_id=hc_group_id
  end

  def asset_id
    @asset_id
  end

  def asset_id=(id)
    @asset_id=id
  end
  
  def approval_status
    @approval_status
  end

  def approval_status=(approval_status)
    @approval_status=approval_status
  end
  
  def suppress_name
    @suppress_name
  end
  def suppress_name=(suppress_name)
    @suppress_name=suppress_name
  end
   
##  def suppress_class
##    suppress_class
##  end
##  def suppress_class=(value)
##    @suppress_class =value
##  end
#
  def automatic_suppress_flag
    @automatic_suppress_flag
  end
  def automatic_suppress_flag=(value)
    @automatic_suppress_flag = value
  end
   
  def vuln_id
    @vuln_id
  end
  def vuln_id=(value)
    @vuln_id=value
  end
  def org_id
    @org_id
  end
  def org_id=(value)
    @org_id=value
  end

  private

  # query for paination for review
  def self.find_exceptions
    RAILS_DEFAULT_LOGGER.debug "ExceptionSearch.find_exceptions, @org_id: #{@org_id.inspect}"
    org = Org.find(@org_id)
    RAILS_DEFAULT_LOGGER.debug "ExceptionSearch.find_exceptions, org: #{org.inspect}"
    RAILS_DEFAULT_LOGGER.debug "ExceptionSearch.find_exceptions, conditions: #{conditions.inspect}"
    RAILS_DEFAULT_LOGGER.debug "ExceptionSearch.find_exceptions, joins_condition: #{joins_condition.inspect}"

    suppressions = Suppression.find(:all, :conditions => "(org_l1_id, org_id) = (#{@org_id})")
    suppressions.paginate :page => @page, :conditions =>conditions, :joins=>joins_condition,
     :order=>"suppress_name #{@sort}", :per_page=>@per_page
  end


  def self.joins_condition
    joins = []
   # joins.push(" LEFT JOIN hip_suppress_group_v ON hip_suppress_group_v.suppress_id=hip_suppress_v.suppress_id ") unless @hc_group_id.downcase=='all'
  end

#  def self.hc_group_id_conditions
#    ["hip_suppress_group_v.hc_group_id = ?", @hc_group_id] unless @hc_group_id.downcase=='all'
#  end


#  def self.asset_id_conditions
#    ["asset_id = ?",@asset_id] unless @asset_id.blank?
#  end

#  def self.vuln_id_conditions
#    ["vuln_id = ?",@vuln_id ] unless @vuln_id.blank?
#  end
  
  def self.suppress_class_conditions
    ["suppress_class = ?",@suppress_class] unless @suppress_class.downcase=='all'
  end
  
#  def self.approval_status_conditions
#    ["approval_status = ?",@approval_status] unless @approval_status.downcase=='all'
#  end

  def self.suppress_name_conditions
    ["lower(suppress_name) like ?","%#{@suppress_name.downcase.strip}%"] unless @suppress_name.blank?
  end

#  def self.auto_suppress_flag_conditions
#    ["automatic_suppress_flag = ?",@automatic_suppress_flag] unless @automatic_suppress_flag.downcase=='all'
#  end

  def self.conditions
    [conditions_clauses.join(' AND '), *conditions_options] unless conditions_options.blank?
  end

  def self.conditions_clauses
    conditions_parts.map { |condition|  condition.first }
  end

  def self.conditions_options

    conditions_parts.map { |condition| condition[1..-1] }.flatten
  end

  def self.conditions_parts
    self.methods.grep(/_conditions$/).map { |m| send(m) }.compact
  end
end
