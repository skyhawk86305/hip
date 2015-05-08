Rake.application.remove_task 'db:test:prepare'

namespace :db do
    
  desc "For PostgreSQL adapters, creates the schema specified by the first element of the schema_search_path"
  task :create_schema => :load_config do
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    if config['adapter'] == 'postgresql'
      schema_search_path = config.delete("schema_search_path")
      if !schema_search_path.nil?
        schema = schema_search_path.split(',')[0]
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Base.connection.execute("create schema #{schema}")
        ActiveRecord::Base.remove_connection
      end
    end
  end
  #overwrite db:drop for DB2
  desc "For IBM_DB adapters, drops the SWARE_L alias and SWARE DB.  Needs to run from DB2 Command Line Processor"
  task :drop => :load_config do
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    if config['adapter'] == 'ibm_db'
      #puts "#{config['database']}: " +  `db2 -v uncatalog db #{config['alias']}`
      puts "#{config['database']}: " +  `db2 -v drop database #{config['database']}`
    end
  end

  #overwrite db:create for DB2
  desc "For IBM_DB adapters, create the sware DB and SWARE_L alias. Needs to run from DB2 Command Line Processor"
  task :create => :load_config do
    db = ActiveRecord::Base.configurations[RAILS_ENV]
    begin
      ActiveRecord::Base.establish_connection(db)
      ActiveRecord::Base.connection
    rescue
      if db['adapter'] == 'ibm_db'
        ddl_file_orig = Rails.root.join('db/db2_ddl/db_config_options.sql')
        ddl_file      = Rails.root.join('db/db2_ddl/db_config_options.last.sql')
        ddl = File.read(ddl_file_orig)
        ddl = ddl.gsub(/<database>/,   db['database'])
        File.delete(ddl_file) if File.exist?(ddl_file)
        File.open(ddl_file, 'w') do |f|
          f.write ddl
        end
        puts "#{db['database']}: " + `db2 create database #{db['database']} AUTOMATIC STORAGE YES USING CODESET UTF-8 TERRITORY US COLLATE USING SYSTEM PAGESIZE 4096`
        puts "#{db['database']}: " + `db2 -td} -s -f #{ddl_file}`
        puts "#{db['database']}: " + `db2 UPDATE DB CFG FOR #{db['database']} USING logarchmeth1 OFF logarchmeth2 OFF logprimary 13 logsecond 10 logfilsiz 32000`
      end
    else
      puts "#{db['database']} already exists"
    end
  end

  #overwrite the rails db:test:prepare for db2
  namespace :test do
    desc "Purge the database"
    task :purge do
      config = ActiveRecord::Base.configurations[RAILS_ENV]
      if config['adapter'] == 'ibm_db'
        # over write purge, which we won't use.  instead the next step of the test is
        # db:test:prepare, see below
        puts "#{config['adapter']} processing purge"

      end
    end
    desc "Prepare the test database with db:drop, db:create,db:migrate"
    task :prepare => 'db:abort_if_pending_migrations' do
      puts "NOT resetting the database; if it needs to be reset please do it manually"
    end
  end
end

namespace :hip do
  
  desc "Create database and schema.  Needs to run from DB2 Command Line Processor"
  task :create => ["db:create"]

  desc "Drop and re-create database and schema. Needs to run from DB2 Command Line Processor"
  task :reset => ["db:drop", "db:create",  "db:migrate"]

  desc "Drop and re-create database and schema, and seed the db. Needs to run from DB2 Command Line Processor"
  task :reset_seed => ["db:drop", "db:create", "db:migrate","db:seed"]
end
