class MigrateDdl


  def self.ddl_file(file)
    status=false
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      config = ActiveRecord::Base.configurations[RAILS_ENV]
      ENV['PGPASSFILE']="#{RAILS_ROOT}/db/pgpass.conf"
      Dir.chdir("#{RAILS_ROOT}")
      cmd=pgpath+" -U #{config['username']} -q -f #{file} --dbname=#{config['database']}"
      if self.has_psql
        status=system "#{cmd}"
        if status
          puts "Migration for #{file} Successful!"
        else
          raise RuntimeError, "Migration for #{file} Failed."
        end
      else
        raise RuntimeError, "psql not found in PATH:"
      end
    end
    status
  end

  private
  def self.has_psql
    system(pgpath+" --version")
  end

  def self.pgpath
    pgpath="psql"
  end
end
