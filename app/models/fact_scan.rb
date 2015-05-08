class FactScan < SwareBase

  set_table_name("fact_scan_v")
  set_primary_keys :finding_vid

  belongs_to :org, :primary_key=>[:org_l1_id,:org_id],:foreign_key=>[:org_l1_id,:org_id]
  belongs_to :asset_scan, :primary_key=>[:asset_id],:foreign_key=>:asset_id
  belongs_to :vuln
  belongs_to :tool ,:primary_key=>:tool_id,:foreign_key=>:scan_tool_id
  belongs_to :suppress_finding,  :primary_key=>[:suppress_id,:finding_id], :foreign_key=>:finding_id
  belongs_to :scan_finding, :primary_key=>:finding_id, :foreign_key=>:finding_id

  before_save :set_lu_data
  before_save :invalidate_deviation_search_cache_both
  before_destroy :invalidate_deviation_search_cache_both
  
  attr_readonly :finding_vid
  attr_readonly :finding_id
  attr_readonly :row_from_timestamp
  attr_readonly :row_from_date_id
  attr_readonly :row_to_timestamp
  attr_readonly :row_to_date_id
  attr_readonly :row_to_date_id_gen
  attr_readonly :scan_timestamp
  attr_readonly :asset_id
  attr_readonly :org_id
  attr_readonly :org_l1_id
  attr_readonly :org_l1_id_gen
  attr_readonly :scan_service
  attr_readonly :scan_tool_id
  attr_readonly :vuln_id
  attr_readonly :severity_id
  attr_readonly :port
  attr_readonly :protocol_id
  attr_readonly :quality_id
  attr_readonly :finding_hash
  attr_readonly :finding_text
  
  # This override of delete_all is needed since delete_all does not call any of the defined callbacks
  # Note also that the super method will not work in this case since it is dynamically assoicated
  # with methods
  def self.delete_all(conditions = nil)
    invalidate_deviation_search_cache_both
    sql = "DELETE FROM #{quoted_table_name} "
    add_conditions!(sql, conditions, scope(:find))
    connection.delete(sql, "#{name} Delete all")
  end
  
  # Note:  The two over ridden methods below, override methods in composit_keys.  They have
  # been modified to supply the second "false" parameter to attriburtes_with_quotes.  This
  # causes the "attr_readonly" to be ignored for both create and update
  private
  
  def create_without_callbacks
    unless self.id
      raise CompositeKeyError, "Composite keys do not generated ids from sequences, you must provide id values"
    end
    attributes_minus_pks = attributes_with_quotes(false, false)
    quoted_pk_columns = self.class.primary_key.map { |col| connection.quote_column_name(col) }
    cols = quoted_column_names(attributes_minus_pks) << quoted_pk_columns
    vals = attributes_minus_pks.values << quoted_id
    connection.insert(
      "INSERT INTO #{self.class.quoted_table_name} " +
      "(#{cols.join(', ')}) " +
      "VALUES (#{vals.join(', ')})",
      "#{self.class.name} Create",
      self.class.primary_key,
      self.id
    )
    @new_record = false
    return true
  end

  # Updates the associated record with values matching those of the instance attributes.
  def update_without_callbacks
    where_clause_terms = [self.class.primary_key, quoted_id].transpose.map do |pair| 
      "(#{connection.quote_column_name(pair[0])} = #{pair[1]})"
    end
    where_clause = where_clause_terms.join(" AND ")
    connection.update(
      "UPDATE #{self.class.quoted_table_name} " +
      "SET #{quoted_comma_pair_list(connection, attributes_with_quotes(false, false))} " +
      "WHERE #{where_clause}",
      "#{self.class.name} Update"
    )
    return true
  end
  
end
