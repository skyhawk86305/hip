class HipAuthViaBluePages
    
  # this class depends on Net::LDAP
  
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
    result = { :name => '', :authenticated => false, :roles => [], :user => nil }
    if userid = params[class_config[:userid_parm_name]]
      password = params[class_config[:password_parm_name]]
      return result if userid.empty? or password.empty?
      result[:name] = userid
      if dn = blue_pages_login_check(userid, password, class_config)
        bluegroups = fetch_blue_group_names(dn, class_config)
        result[:user] = User.new(result[:name], bluegroups)
        result[:roles] = result[:user].roles
        # Note:  The authenticated flag is set last so that if any exceptions occure, we will
        # not return a questionable credential with authenticated set to true
        result[:authenticated] = true
      end
    end
    return result
  end
  
  ##########
  protected
  ##########
  
  ############################################################################################
  #
  # blue_pages_login_check
  #
  ############################################################################################
   def blue_pages_login_check(userid, password, class_config)
    # returns the DN on successful authentication, nil otherwise
    # TODO: consider changing this from ldap.bind_as to a search & bind so that we can error
    # when the anonymous search fails vs. not finding anything.
    ldap = Net::LDAP.new(:host => class_config[:authentication_host], :auth => {:method => :anonymous})
    result = ldap.bind_as(:base => class_config[:authentication_base],
      :filter => "#{class_config[:authentication_userid_attribute]}=#{userid}",
      :password => password,
      :encryption => class_config[:authentication_encryption],
      :port => class_config[:authentication_port])
    return nil unless result
    return self.class.get_attribute(result[0], :dn)
  end
  
  ############################################################################################
  #
  # fetch_blue_group_roles
  #
  ############################################################################################
   def fetch_blue_group_names(dn, class_config)
    ldap = Net::LDAP.new(:host => class_config[:group_host], :auth => {:method => :anonymous})
    filter = Net::LDAP::Filter.eq("uniquemember" , dn)
    if class_config[:group_filter]
      filter = filter & Net::LDAP::Filter.construct(class_config[:group_filter])
    end
    results = ldap.search(:base => class_config[:group_base], :filter => filter, :attributes => ['cn'])
    raise AuthorizationLogin::AuthorizationError, "LDAP Error looking up groups:  #{ldap.get_operation_result}" unless results
    return results.map do |entry|
      blue_group_name = self.class.get_attribute(entry, :cn)
    end.flatten.compact.uniq
  end
  
  ############################################################################################
  #
  # self.get_attribute
  #
  ############################################################################################
   def self.get_attribute(result, attribute)
    return result.attribute_names.include?(attribute) ? result[attribute.to_s][0] : nil
  end
    
end