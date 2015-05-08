require 'composite_primary_keys'
#
# The following is a Monkey patch to ibm_db to return smallint as an integer instead of a boolean
#
module ActiveRecord
  module ConnectionAdapters
    class IBM_DBColumn < Column

      def simplified_type(field_type)
        case field_type
          # if +field_type+ contains 'for bit data' handle it as a binary
          when /for bit data/i
            :binary
          when /smallint/i
            #:boolean
            :integer
          when /int|serial/i
            :integer
          when /decimal|numeric|decfloat/i
            :decimal
          when /float|double|real/i
            :float
          when /timestamp|datetime/i
            :timestamp
          when /time/i
            :time
          when /date/i
            :date
          when /vargraphic/i
            :vargraphic
          when /graphic/i
            :graphic
          when /clob|text/i
            :text
          when /xml/i
            :xml
          when /blob|binary/i
            :binary
          when /char/i
            :string
          when /boolean/i
            :boolean
          when /rowid/i  # rowid is a supported datatype on z/OS and i/5
            :rowid
        end
      end # method simplified_type

    end
  end
end

class SwareBase < ActiveRecord::Base
  
  DEFAULT_LU_USERID = "hip_application"
  
  def self.current_period_id
    fetch_period_ids
    @@current_period.id
  end
  
  def self.current_period
    fetch_period_ids
    @@current_period
  end
  
  def self.current_month_period_id
    fetch_period_ids
    @@current_month_period.id
  end
  
  def self.current_month_period
    fetch_period_ids
    @@current_month_period
  end
  
  def self.HcCycleAssetFreezeTimestamp
    current_period.asset_freeze_timestamp
  end
  
  def self.set_period(date)
    @@period_override_date = date
    @@last_fetch_time = nil
    fetch_period_ids
  end
  
  def self.reset_period
    remove_class_variable(:@@period_override_date)
    @@last_fetch_time = nil
    fetch_period_ids
  end
  
  def self.vuln_ids_to_ignore
    [135972].join(",")
  end
  
  def self.username
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    config['username']
  end
  
  def self.query_with_temp_table(table_name, prototype_select, index_columns, load_sql, query)
    # table_name:  (string) simple table name -- do not include a schema name
    # prototype_select:  (string) select statement that returns the columns that are to be defined for the temp table
    # index_columns:  (array of strings) list of the columns that an index should be created on
    # load_sql: (string or array) an sql statement that will load the temoryary table in the format used by find_by_sql
    # query:  (string or array) an sql select statement that will use the temoryary table in the format used by find_by_sql
    connection.execute("declare global temporary table #{table_name} as (#{prototype_select})
      definition only with replace on commit preserve rows not logged")
    connection.execute("create index session.#{table_name}_key on session.#{table_name} (#{index_columns.join(', ')})")
    result = connection.execute(load_sql)
    if !query.nil?
      result = find_by_sql(query)
      connection.execute("drop table session.#{table_name}")
      return result
    end
    return nil
  end

  def self.truncate_userid(userid, model = nil)
    model = self if model.nil?
    column = model.columns_hash["lu_userid"]
    column = model.columns_hash["created_by"] if column.nil?
    column_limit = column.nil? ? HipPeriod.columns_hash["lu_userid"].limit : column.limit
    return userid[0...column_limit]
  end
  
  ##########
  private
  ##########
  
  def set_lu_data
    self.lu_timestamp = Time.now.utc
    if self.class.columns_hash.has_key?("lu_userid")
      self.lu_userid = self.lu_userid? ? self.lu_userid[0...self.class.columns_hash["lu_userid"].limit] : DEFAULT_LU_USERID
    end
  end
  
  def set_created_at
    self.created_at = Time.now.utc
  end
  
  def self.db2?
    self.connection.instance_of?(ActiveRecord::ConnectionAdapters::IBM_DBAdapter)
  end
  
  def self.fetch_period_ids
    @@last_fetch_time = nil unless defined?(@@last_fetch_time)
    if @@last_fetch_time.nil? || @@last_fetch_time.year != Time.now.utc.year || @@last_fetch_time.month != Time.now.utc.month
      if defined?(@@period_override_date)
        @@last_fetch_time = Time.now.utc
        @@current_period = HipPeriod.find(:first, :conditions => {:year => @@period_override_date.year, :month_of_year => @@period_override_date.month})
        @@current_month_period = ScanPeriod.find(:first, :conditions => {:year => @@period_override_date.year, :month_of_year => @@period_override_date.month})
      else
        @@last_fetch_time = Time.now.utc
        @@current_period = HipPeriod.current_period[0]
        @@current_month_period = ScanPeriod.current_period[0]
      end
    end
  end
  
  def self.user_id
    if Thread.current[:current_user]
      return Thread.current[:current_user].userid
    else
      return DEFAULT_LU_USERID
    end
  end
  
  def self.current_org_id
    Thread.current[:org_id]
  end
  
  def self.invalidate_deviation_search_cache_incycle
    RAILS_DEFAULT_LOGGER.debug "invalidating deviation search cache incycle" 
    FindingCacheSet.invalidate_cache(:incycle)
  end
  
  def invalidate_deviation_search_cache_incycle
    self.class.invalidate_deviation_search_cache_incycle
  end
  
  def self.invalidate_deviation_search_cache_ooc
    RAILS_DEFAULT_LOGGER.debug "invalidating deviation search cache ooc" 
    FindingCacheSet.invalidate_cache(:ooc)
  end
  
  def invalidate_deviation_search_cache_ooc
    self.class.invalidate_deviation_search_cache_ooc
  end
  
  def self.invalidate_deviation_search_cache_both
    RAILS_DEFAULT_LOGGER.debug "invalidating deviation search cache both" 
    FindingCacheSet.invalidate_cache(:both)
  end
  
  def invalidate_deviation_search_cache_both
    self.class.invalidate_deviation_search_cache_both
  end
  
  def self.set_current_degree(degree)
    original_degree = get_current_degree
    sql_set_statement = "set current degree = '#{degree}'"
    if block_given?
      connection.execute(sql_set_statement)
      begin
        result = yield
      ensure
        connection.execute("set current degree = '#{original_degree}'")
      end
      return result
    else
      connection.execute(sql_set_statement)
    end
    return original_degree
  end
  
  def self.get_current_degree
    return SwareBase.find_by_sql("with dummy1 (dummy) as (values ('')) select current degree as degree from dummy1")[0].degree
  end
  
end
