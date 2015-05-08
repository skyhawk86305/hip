# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

PROJECT_ROOT=File.dirname(__FILE__)

require 'thread'

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name)
  end
end

require 'rake'
require 'rake/testtask'
#require 'rake/rdoctask'
require 'rdoc/task'
require 'tasks/rails'
