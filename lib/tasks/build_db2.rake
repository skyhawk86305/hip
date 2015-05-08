desc "builds the db2 library in /vendor/gems/ibm_db-smallint-2.5.0/ext
  specify DB2=<db2 instance name> to tell what userid to use for the libraries when building."
task :build_db2 do
  raise "must specify DB2 instance name, e.g. DB2=db2inst1 rake build_db2" unless ENV['DB2']
  db2user = ENV['DB2']
  db2home = File.expand_path("~#{db2user}")
  ibm_db_dir = File.join(db2home, "sqllib")
  profile = File.join(ibm_db_dir, "db2profile")
  ibm_db_plugin_dir = File.join(RAILS_ROOT, "vendor", "gems", "ibm_db-smallint-2.5.0")
  ext_dir = File.join(ibm_db_plugin_dir, "ext")
  if RUBY_PLATFORM =~ /darwin/
    ibm_db_so = File.join(ext_dir, "ibm_db.bundle")
    ibm_db_app_lib = File.join(ibm_db_plugin_dir, "lib", "ibm_db.bundle")
  else
    ibm_db_so = File.join(ext_dir, "ibm_db.so")
    ibm_db_app_lib = File.join(ibm_db_plugin_dir, 'lib', 'ibm_db.so')
  end
  sh <<-EOS
    . #{profile} &&
    cd #{ext_dir} &&
    ruby extconf.rb --with-IBM_DB-dir=#{ibm_db_dir} && make &&
    mv #{ibm_db_so} #{ibm_db_app_lib}
  EOS
end
