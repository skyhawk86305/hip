#require 'mongrel_cluster/recipes'
#require 'bundler/capistrano'

set :application, "hip"
set :scm, :subversion
set :deploy_via, :export

set :user, "hip"
set :use_sudo, false

set :syntax_example, "cap <environment> deploy"
set(:deploy_to) {raise "must specify the environment in which to run, e.g. #{syntax_example}"}
#set(:mongrel_conf) { deploy_to }

# svn_release is the SVN directory in the /release directory to deploy.  e.g. 1.1.1 which will use <svn base url>/releases/1.1.1
#set(:svn_release) {raise "must specify the release to deploy, e.g. #{syntax_example}"}

#role :app, "your app-server here"
#role :web, "your web-server here"
#role :db,  "your db-server here", :primary => true

###################################################
#
# Environment Tasks
#
###################################################
# LocalStaging
###################################################
desc "run in local staging environment"
task :local_staging do
  server "localhost", :app, :web, :db, :primary => true
  
  release = ENV['RELEASE'] || nil
  if release.nil?
    set :repository,  "svn+ssh://msd-bld-dev-01.boulder.ibm.com/www/svn/hip/trunk"
  else
    set :repository,  "svn+ssh://msd-bld-dev-01.boulder.ibm.com/www/svn/hip/releases/#{release}"
  end
    
  set :deploy_to, "/www/#{application}_local_staging"
  set :log_to, "#{deploy_to}/shared/log/local_staging.log"
  
  set :db2instance, 'db2i1'
  set :rails_env, 'local_staging'

  # The following mongrel configuration is disabled as part of moving to passenger
  #set :mongrel_servers, 2
  #set :mongrel_port, 8300
  #set :mongrel_address, "127.0.0.1"
  #set :mongrel_environment, rails_env
  #set :mongrel_conf, "#{deploy_to}/shared/mongrel_cluster.yml"
  #set :mongrel_pid_file, "#{deploy_to}/shared/pids/mongrel.pid"
end

###################################################
# Staging
###################################################
desc "run in staging environment"
task :staging do
  server "msd-bld-dev-01.boulder.ibm.com", :app, :web, :db, :primary => true
  
  release = ENV['RELEASE'] || nil
  if release.nil?
    set :repository,  "svn+ssh://msd-bld-dev-01.boulder.ibm.com/www/svn/hip/trunk"
  else
    set :repository,  "svn+ssh://msd-bld-dev-01.boulder.ibm.com/www/svn/hip/releases/#{release}"
  end
    
  set :deploy_to, "/www/#{application}_staging"
  set :log_to, "#{deploy_to}/shared/log/staging.log"
  
  set :db2instance, 'db2i1'
  set :rails_env, 'staging'

  #set :mongrel_servers, 2
  #set :mongrel_port, 8300
  #set :mongrel_address, "127.0.0.1"
  #set :mongrel_environment, rails_env
  #set :mongrel_conf, "#{deploy_to}/shared/mongrel_cluster.yml"
  #set :mongrel_pid_file, "#{deploy_to}/shared/pids/mongrel.pid"
end

###################################################
# ETL-Test
###################################################
desc "run in etl-test environment"
task :etltest do
  server "msd-bld-dev-01.boulder.ibm.com", :app, :web, :db, :primary => true
  
  release = ENV['RELEASE'] || nil
  if release.nil?
    set :repository,  "svn+ssh://msd-bld-dev-01.boulder.ibm.com/www/svn/hip/trunk"
  else
    set :repository,  "svn+ssh://msd-bld-dev-01.boulder.ibm.com/www/svn/hip/releases/#{release}"
  end
    
  set :deploy_to, "/www/#{application}_etl-test"
  set :log_to, "#{deploy_to}/shared/log/staging.log"
  
  set :db2instance, 'db2i1'
  set :rails_env, 'etl-test'
  
  set :db2instance, 'db2i1'
  set :rails_env, 'staging'

  #set :mongrel_servers, 2
  #set :mongrel_port, 8300
  #set :mongrel_address, "127.0.0.1"
  #set :mongrel_environment, rails_env
  #set :mongrel_conf, "#{deploy_to}/shared/mongrel_cluster.yml"
  #set :mongrel_pid_file, "#{deploy_to}/shared/pids/mongrel.pid"
end

###################################################
# Production
###################################################
desc "run in production environment"
task :production do
  server "msd-bld-web-03p.boulder.ibm.com", :app, :web, :db, :primary => true
  
  release = ENV['RELEASE'] || nil
  if release.nil?
    set(:repository) {raise "must specify a relase to be deployed (via the RELEASE environment variable)"}
  else
    set :repository,  "svn+ssh://msd-bld-dev-01.boulder.ibm.com/www/svn/hip/releases/#{release}"
  end
    
  # set :rails_trunk, "/www/rails" # for symlinking into vendor/rails. deploy will issue svn up!
  set :deploy_to, "/www/#{application}_production"
  set :log_to, "#{deploy_to}/shared/log/production.log"
  
  set :db2instance, 'db2i1'
  set :rails_env, 'production'

  #set :mongrel_servers, 10
  #set :mongrel_port, 8300
  #set :mongrel_address, "127.0.0.1"
  #set :mongrel_environment, rails_env
  #set :mongrel_conf, "#{deploy_to}/shared/mongrel_cluster.yml"
  #set :mongrel_pid_file, "#{deploy_to}/shared/pids/mongrel.pid"
end


###################################################
#
# Deployment
#
###################################################
namespace :deploy do
  
  #after "deploy:setup", "mongrel:cluster:configure"
  #  task :after_setup do
  #    find_and_execute_task("mongrel:cluster:configure")
  #  end
  
  #after "deploy:update_code", "deploy:build_db2",
  after "deploy:update_code", 
    "deploy:set_permissions",
    "deploy:update_revision_file",
  #  "deploy:restart",
    "deploy:cleanup"
  #  task :after_update_code do
  #    build_db2
  #    set_permissions
  #    update_revision_file
  #  end
  
  before "deploy:set_permissions", "deploy:touch_log_file"
  #  task :before_set_permissions do
  #    touch_log_file
  #  end
  
  #before "deploy:rollback", "mongrel:cluster:stop"
  #  task :before_rollback do
  #    find_and_execute_task("mongrel:cluster:stop")
  #  end

  #after  "deploy:rollback", "mongrel:cluster:start"
  #  task :after_rollback do
  #    find_and_execute_task("mongrel:cluster:start")
  #  end

  after "deploy:finalize_update", "deploy:extra_symlink"
  
  after "deploy:setup", "deploy:setup_extra_dirs"
  
  #desc "Starts the mongrel cluster (replaces default task)" 
  #task :start, :roles => :app do
  #  # find_and_execute_task("mongrel:cluster:start")
  #  run "touch #{File.join(release_path,'tmp','restart.txt')}"
  #end
  
  #desc "Restarts the mongrel cluster (replaces default task)"
  #task :restart, :roles => :app, :except => { :no_release => true } do
  #  #find_and_execute_task("mongrel:cluster:restart")
  #  run "touch #{File.join(release_path,'tmp','restart.txt')}"
  #end
  
  #desc "Stops the mongrel cluster (replaces default task)"
  #task :stop, :roles => :app do
  #  #find_and_execute_task("mongrel:cluster:stop")
  #end
    
  desc "Modify file permissions to allow the group to have access"
  task :add_group_permissions do
    puts "adding group permissions..."
    run "cd #{release_path} && chmod -R g+rX ."
    run "chmod g+r #{log_to}"
  end

  desc "Insure that the application log file exists"
  task :touch_log_file do
    puts "touching log file..."
    run "touch #{log_to}"
  end
  
  desc "Display the value of :repository"
  task :display_repository do
    puts "repository: #{repository}"
  end
  
  # Override the setup task -- only create the deploy_to directory if it doesn't already exist
  desc <<-DESC
      Prepares one or more servers for deployment. Before you can use any \
      of the Capistrano deployment tasks with your project, you will need to \
      make sure all of your servers have been prepared with `cap deploy:setup'. Wh
  en \
      you add a new server to your cluster, you can easily run the setup task \
      on just that server by specifying the HOSTS environment variable:

        $ cap HOSTS=new.server.com deploy:setup
      It is safe to run this task on servers that have already been set up; it \
      will not destroy any deployed revisions or data.
  DESC
  task :setup, :except => { :no_release => true } do
    dirs = [releases_path, shared_path]
    if !File.exist?(deploy_to)
      dirs.unshift(deploy_to)
    end
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
  end
    
  desc "Set file and directory permissions"
  task :set_permissions do
    puts "Setting file and directory premissions ..."
    #run "chmod 2775 #{deploy_to}"
    run "find #{release_path} -type d ! -name '.' -exec chmod 2775 {} \\;"
    run "find #{release_path} -type f ! -perm -u=x -exec chmod 664 {} \\;"
    run "find #{release_path} -type f -perm -u=x -exec chmod 775 {} \\;"
    run "find #{shared_path} -type d ! -name '.' -exec chmod 2775 {} \\;"
    run "find #{shared_path} -type f ! -perm -u=x -exec chmod 664 {} \\;"
    run "find #{shared_path} -type f -perm -u=x -exec chmod 775 {} \\;"
    run "chmod 777 #{shared_path}/mhc_files"
    run "chmod 777 #{shared_path}/mhc_files/archive"
  end
    
  #desc "Callback to build the db2 library for this system based on DB2INSTANCE environment variable.
  #  This is done after every deployment in case the db2 library code has been updated"
  #task :build_db2 do
  #  run "cd #{release_path}; rake build_db2 DB2=#{db2instance}" # calls the rakefile
  #end
    
  desc <<-DESC
      This task sets up the symlink to the shared extra directories
  DESC
  task :extra_symlink, :except => { :no_release => true } do
    run <<-CMD
        rm -rf #{latest_release}/reports &&
        ln -s #{shared_path}/reports #{latest_release}/reports
    CMD
      
    run <<-CMD
        rm -rf #{latest_release}/offline_suppression_files &&
        ln -s #{shared_path}/offline_suppression_files #{latest_release}/offline_suppression_files
    CMD
      
    run <<-CMD
        rm -rf #{latest_release}/mhc_files &&
        ln -s #{shared_path}/mhc_files #{latest_release}/mhc_files
    CMD
    
    # setup config file
    run <<-CMD
        rm -rf #{latest_release}/config/hip_config.yml &&
        ln -s #{shared_path}/hip_config.yml #{latest_release}/config/hip_config.yml
    CMD
  end
    
  desc <<-DESC
      This tasks creates the extra shared directories
  DESC
  task :setup_extra_dirs, :except => { :no_release => true } do
    reports_dir = File.join(shared_path, "reports")
    offline_dir = File.join(shared_path, "offline_suppression_files")
    mhc_dir = File.join(shared_path, "mhc_files")
    run "#{try_sudo} mkdir -p #{reports_dir} && #{try_sudo} chmod g+w #{reports_dir}"
    run "#{try_sudo} mkdir -p #{offline_dir} && #{try_sudo} chmod g+w #{offline_dir}"
    run "#{try_sudo} mkdir -p #{mhc_dir} && #{try_sudo} chmod g+w #{mhc_dir}"
  end    
    
  task :update_revision_file do
    run "cd #{release_path} && echo '#{repository}' >> REVISION"
    run "cd #{release_path} && echo 'Deploying Userid: #{%x(echo "$(whoami)@$(hostname)").chomp}' >> REVISION"
  end

  desc "Hard restart the passenger instances by killing the dispatcher"
  task :hard_restart, :roles => :app, :except => {:no_release => true} do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
    run "pkill -9 -f '^Rails: #{deploy_to}' || true"
    run "pkill -9 -f '^Passenger ApplicationSpawner: #{deploy_to}' || true"
  end 
end
