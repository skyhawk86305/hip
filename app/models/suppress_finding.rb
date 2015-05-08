class SuppressFinding < SwareBase

  set_table_name("hip_suppress_finding_v")
  set_primary_keys [:suppress_id,:finding_id]

  belongs_to :suppression, :primary_key=>:suppress_id, :foreign_key=>:suppress_id
  has_one :fact_scan,:primary_key=>:finding_vid, :foreign_key=>:finding_id

  before_save :set_lu_data
  before_save :invalidate_deviation_search_cache_both
  before_destroy :invalidate_deviation_search_cache_both
  
  # This override of delete_all is needed since delete_all does not call any of the defined callbacks
  # Note also that the super method will not work in this case since it is dynamically assoicated
  # with methods
  def self.delete_all(conditions = nil)
    invalidate_deviation_search_cache_both
    sql = "DELETE FROM #{quoted_table_name} "
    add_conditions!(sql, conditions, scope(:find))
    connection.delete(sql, "#{name} Delete all")
  end
    
  def self.create_all!(suppress_findings)
    # Expects scan_findings to be an array of hashes to be used for create, or a simple hash for create
    # In the array, all hashes must have the same set of keys
    invalidate_deviation_search_cache_both
    if ! suppress_findings.respond_to?('[]')
      create! suppress_findings
    else
      size = suppress_findings.size
      current = 0
      increment = 500
      while current < size
        delete = create_multiple_delete(suppress_findings[current, increment])
        insert = create_multiple_insert(suppress_findings[current, increment])
        SuppressFinding.transaction do
          SuppressFinding.connection.execute(delete)
          SuppressFinding.connection.execute(insert)
        end
        current += increment
      end
    end
  end
  
  def self.delete_all!(suppress_findings)
    if ! suppress_findings.respond_to?('[]')
      delete_all([ "finding_id = ?", suppress_findings[:finding_id] ])
    else
      size = suppress_findings.size
      current = 0
      increment = 500
      while current < size
        delete = create_multiple_delete(suppress_findings[current, increment])
        SuppressFinding.transaction do
          SuppressFinding.connection.execute(delete)
        end
        current += increment
      end
    end
  end
      

  # Note:  The two over ridden methods below, override methods in composit_keys.  They have
  # been modified to supply the second "false" parameter to attriburtes_with_quotes.  This
  # causes the "attr_readonly" to be ignored for both create and update
  private

  def self.create_multiple_insert(suppress_findings)
    #scan_findings must be an array of hashes, all hashes must have the same set of keys
    keys = suppress_findings[0].keys
    result = "INSERT INTO #{table_name} (lu_timestamp, #{keys.join(', ')}) values "
    suppress_findings.each do |sf|
      insert_value_string = "(current_timestamp, "
      keys.each do |column|
        if column.to_s == "lu_userid"   # Note:  Do not generalize this test, we only want to truncate userids
          insert_value_string << quote_value(sf[column][0...columns_hash["lu_userid"].limit])
        else
          insert_value_string << quote_value(sf[column])
        end
        insert_value_string << ","
      end
      insert_value_string[-1] = ')'
      insert_value_string << ','
      result << insert_value_string
    end
    result.chop!
    result
  end
  
  def self.create_multiple_delete(suppress_findings)
    # suppress_findings must be an array of hashes that have a :finding_id element
    return nil if suppress_findings.empty?
    finding_ids = suppress_findings.map {|sf| sf[:finding_id]}
    finding_ids.uniq!
    finding_ids_string = finding_ids.join(',')
    sql = "delete from #{table_name} where finding_id in (#{finding_ids_string})"
    return sql
  end
end
