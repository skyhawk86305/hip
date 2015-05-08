class Suppression < SwareBase
  attr_accessor :vuln_title,:asset,:hc_group_ids,:system_name,:start_timestamp_formated,:end_timestamp_formated
  
  HUMANIZED_COLUMNS = {:vuln_title => "Deviation Type", :suppress_name=>"Suppression Name",
    :suppress_desc => "Suppression Description", :suppress_class => "Classification",
    :end_timestamp =>"End Date",:start_timestamp =>"Start Date"
  }

  set_table_name("hip_suppress_v")
  set_primary_key :suppress_id

  belongs_to :vuln
  belongs_to :org, :primary_key=>[:org_l1_id,:org_id], :foreign_key=>[:org_l1_id,:org_id]
  belongs_to :asset, :primary_key=>:tool_asset_id,:foreign_key=>:asset_id
  belongs_to :suppress_finding,  :primary_key=>:suppress_id, :foreign_key=>:suppress_id
  belongs_to :suppress_group, :primary_key=>[:suppress_id,:hc_group_id],:foreign_key=>:suppress_id

  before_save :set_lu_data
  before_save :invalidate_deviation_search_cache_both
  before_destroy :invalidate_deviation_search_cache_both
  before_validation :end_timestamp_end_of_month
  
  validates_presence_of :start_timestamp,:end_timestamp,:suppress_name,:suppress_desc,
    :suppress_class
  validates_presence_of :system_name, :if=>:require_asset
  validates_presence_of :hc_group_ids, :if=>:require_hc_group_ids
  validates_presence_of :vuln_title, :if=>:require_vuln_title
  validates_size_of :suppress_desc, :maximum=>500
  validates_size_of :suppress_name, :maximum=>100
  #validate timestamp constraints
  validate :validate_end_timestamp, :if=>:start_timestamp
  #validate :validate_start_timestamp # to  use later??

  named_scope :exception_list, :conditions=>["automatic_suppress_flag = 'n' and end_timestamp > current_timestamp"]


  # This override of delete_all is needed since delete_all does not call any of the defined callbacks
  # Note also that the super method will not work in this case since it is dynamically assoicated
  # with methods
  def self.delete_all(conditions = nil)
    invalidate_deviation_search_cache_both
    sql = "DELETE FROM #{quoted_table_name} "
    add_conditions!(sql, conditions, scope(:find))
    connection.delete(sql, "#{name} Delete all")
  end
  
  def selected_hc_group_ids
    array=[]
    sg= SuppressGroup.find_all_by_suppress_id(self.suppress_id)
    sg.each do |a|
      array.push(a.hc_group_id)
    end
    array
  end

  def require_asset
    self.automatic_suppress_flag=='y' and self.apply_to_scope=='asset'
  end
  def require_hc_group_ids
    self.automatic_suppress_flag=='y' and self.apply_to_scope=='group'
  end
  def require_vuln_title
    self.automatic_suppress_flag=='y'
  end

  # create a hash of attribute names
  # to rename for more useful meaning.
  def self.human_attribute_name(attribute)
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end

  def validate_end_timestamp
    errors.add_to_base("End Date must be greater then Start Date") unless  self.end_timestamp.to_i > self.start_timestamp.to_i
  end

  def validate_start_timestamp
    errors.add_to_base("Start Date must equal to or greater then the current month #{Time.now.strftime("%Y-%m-%d")}") unless  Time.now.to_i > self.start_timestamp.to_i
  end

  def start_timestamp_formatted
    self.start_timestamp.strftime("%Y-%m-%d") unless self.start_timestamp.nil?
  end
  def end_timestamp_formatted
      self.end_timestamp.strftime("%Y-%m-%d") unless self.end_timestamp.nil?
  end

  def end_timestamp_end_of_month
    self.end_timestamp=self.end_timestamp.end_of_month unless self.end_timestamp.nil?
  end
end
