class OocGroup < SwareBase

  before_save :set_lu_data

  set_table_name("hip_ooc_group_v")
  set_primary_key :ooc_group_id

  belongs_to :org,:primary_key=>[:org_l1_id,:org_id], :foreign_key =>[:org_l1_id,:org_id]
  has_many :ooc_asset_groups, :primary_key=>[:ooc_group_id,:asset_id], :foreign_key => :ooc_group_id
  
  HUMANIZED_COLUMNS = {:ooc_group_name => "Group Name", :ooc_group_type=>"Group Type",
   :ooc_group_status =>"Group Status"
  }
  
  validates_presence_of :ooc_group_name,:ooc_group_status,:ooc_group_type
  validates_length_of :ooc_group_name, :maximum=>80
  validates_length_of :ooc_group_status, :maximum=>15
  validates_length_of :ooc_group_type, :maximum=>20
  validates_inclusion_of :ooc_group_status, :in => ['active', 'deleted', 'inactive'],:if=>Proc.new { |g| g.ooc_group_status.nil? }
  #validates_inclusion_of :ooc_group_type, :in => ['baseline', 'implementation', 'refresh', 'activation', 'exception hc cycle', 'post remediation', 'test'],
  #  :if=>Proc.new { |g| g.ooc_group_type.nil? }
  validates_uniqueness_of :ooc_group_name,:scope=>[:ooc_group_type,:org_l1_id,:org_id]

  before_save :invalidate_deviation_search_cache_ooc
  before_destroy :invalidate_deviation_search_cache_ooc

  # This override of delete_all is needed since delete_all does not call any of the defined callbacks
  # Note also that the super method will not work in this case since it is dynamically assoicated
  # with methods
  def self.delete_all(conditions = nil)
    invalidate_deviation_search_cache_ooc
    sql = "DELETE FROM #{quoted_table_name} "
    add_conditions!(sql, conditions, scope(:find))
    connection.delete(sql, "#{name} Delete all")
  end

  def self.human_attribute_name(attribute)
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end

end