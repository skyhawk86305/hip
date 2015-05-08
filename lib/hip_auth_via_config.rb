class HipAuthViaConfig
  
  ############################################################################################
  #
  # authenticate
  #
  # PARAMETERS
  #   request
  #   params
  #   session_enabled
  #   class_config
  #   logger
  #
  # Returns:
  # a credential as defined by authorization_login that will be a hash containing the following:
  #    :name          => string             the name of the requestor
  #    :authenticated => boolean            indicates that "name" has been authenticated
  #    :roles         => array of symbols   the names of the roles "name" is in
  #    :user          => User object
  #
  # 
  ############################################################################################
  ############################################################################################
  #
  # initialize
  #
  ############################################################################################
   def initialize(logger)
    @logger = logger
  end
  
  ############################################################################################
  #
  # authenticate
  #
  ############################################################################################
   def authenticate(request, params, session_enabled, class_config)
    if userid = params[class_config[:userid_parm_name]]
      password = params[class_config[:password_parm_name]]
      users = class_config[:users]
      RAILS_DEFAULT_LOGGER.debug "HipAuthViaConfig#authenticate userid: #{userid}" 
      RAILS_DEFAULT_LOGGER.debug "HipAuthViaConfig#authenticate password: #{password}" 
      RAILS_DEFAULT_LOGGER.debug "HipAuthViaConfig#authenticate password: #{users.inspect}" 
      if users[userid] && users[userid][:password] == password
        RAILS_DEFAULT_LOGGER.debug "HipAuthViaConfig#authenticate password match" 
        user = User.new(userid ,users[userid][:bluegroups].nil? ? [] : users[userid][:bluegroups])
        roles = user.roles
        result =  { :name => userid, :authenticated => true, :roles => roles, :user => user }
        RAILS_DEFAULT_LOGGER.debug "HipAuthViaConfig#authenticate result #{result.inspect}" 
        return result
      else
        return { :name => userid, :authenticated => false, :roles => [], :user => nil }
      end
    else
      return { :name => '', :authenticated => false, :roles => [], :user => nil }
    end
  end
  
end