class HipSchemaDoc
  def initialize(db)
    @db = db
    tables.each do |table|
      puts JSON.dump([:tabschema, :tabname].map {|field| table[field].strip})
    end
  end

  def tables
    @tables ||= @db['SELECT * FROM SYSCAT.TABLES'].all.sort_by do |table|
      [table[:tabschema], table[:tabname]]
    end.reject do |table|
      table[:owner].strip == 'SYSIBM'
    end
  end
end

namespace :db do

  namespace :doc do

    desc "Generate/Update HTML documentation for database schema"
    task :schema => :load_config do
      require 'sequel'
      require 'nokogiri'
      require 'json'
      db_config = ActiveRecord::Base.configurations[RAILS_ENV]
      ActiveRecord::Base.establish_connection(db_config)
      db = Sequel.ibmdb(
        :database => db_config['database'],
        :username => db_config['username'],
        :password => db_config['password']
      )
      HipSchemaDoc.new db
      ActiveRecord::Base.remove_connection
    end

  end

end
