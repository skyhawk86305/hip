# A class to manage setting and loading applicaton configuration paramaters
# Reload the config by calling AppConfigLoader.fetch_config_options
# from your controller or intializer.
class AppConfig
  
  def self.read_only_flag
    fetch_config_options  unless defined?(@@read_only_msg)
    @@read_only_flag ||= nil # initiallize it with nil if it's not set in the db
  end

  def self.ooc_read_only_flag
    fetch_config_options  unless defined?(@@ooc_read_only_msg)
    @@ooc_read_only_flag ||= nil # initiallize it with nil if it's not set in the db
  end
  
  def self.read_only_msg
    fetch_config_options  unless defined?(@@read_only_msg)
    @@read_only_msg ||=nil # initiallize it with nil if it's not set in the db
  end

  def self.ooc_read_only_msg
    fetch_config_options  unless defined?(@@ooc_read_only_msg)
    @@ooc_read_only_msg ||=nil # initiallize it with nil if it's not set in the db
  end
  def self.hip_notice
    fetch_config_options  unless defined?(@@hip_notice)
    @@hip_notice ||=nil # initiallize it with nil if it's not set in the db
  end
  
  def self.ooc_exec_dashboard_orgs
    fetch_config_options  unless defined?(@@ooc_exec_dashboard_orgs)
    @@ooc_exec_dashboard_orgs ||=nil # initiallize it with nil if it's not set in the db
  end

  def self.hip_controller_notice(controller_class_name)
    fetch_config_options  unless defined?(@@hip_controller_notices)
    @@hip_controller_notices[controller_class_name]
  end
  
  # load the config options
  def self.fetch_config_options
    config = HipConfig.all

    # Reset @@hip_controller_notices
    @@hip_controller_notices = {}

    #go through the rows and find the key/value to set
    config.each do |c|
      # set the read_only_flag
      if c.key=='read_only_flag'
        @@read_only_flag =  c.value
      end
      
      # set the read only msg
      if c.key=='read_only_msg'
        @@read_only_msg =  c.value
      end

      # set the read only msg
      if c.key=='hip_notice'
        @@hip_notice =  c.value
      end
      if c.key=='ooc_exec_dashboard_orgs'
        @@ooc_exec_dashboard_orgs = c.value
      end
      if c.key=='ooc_read_only_flag'
        @@ooc_read_only_flag =  c.value
      end
      
      # set the read only msg
      if c.key=='ooc_read_only_msg'
        @@ooc_read_only_msg =  c.value
      end

      if c.key == 'controller_notice'
        (controller_name, notice) = c.value.gsub('::', "\b").split(":", 2).map {|s| s.gsub("\b", "::")}
        @@hip_controller_notices[controller_name] = notice
      end
    end
  end
end
