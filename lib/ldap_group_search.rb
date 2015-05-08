class LdapGroupSearch

  def initialize()
    @config = LdapGroupSearch.ldap_config
    @ldap = Net::LDAP.new(:host => @config['bluepages_host'], :auth => {:method => :anonymous})
    # Never return an object in the cache in case the receive of the data modifies teh result
    @cache = {}
  end

  ############################################################################################
  #
  # fetch_blue_group_members
  #
  ############################################################################################
  def fetch_blue_group_members(bluegroup)
    # Never return an object in the cache in case the receive of the data modifies the result
    return @cache[bluegroup].map {|e| e.dup} if @cache.has_key? bluegroup

    members = []
    
    filter = Net::LDAP::Filter.eq("cn", "#{bluegroup}" )
  
    group_members = @ldap.search(:base => @config['bluegroups_base'],
      :filter => filter, :attributes => ['uniquemember'])

    return (@cache[bluegroup] = []).dup if group_members.nil? || group_members[0].nil? || group_members[0]['uniquemember'].nil?
  
    group_members[0]['uniquemember'].each do |dn|
      (name, email_address, job_responsibility, manager) = get_person(dn)
      members << [name, email_address, bluegroup, job_responsibility, manager]
    end

    @cache[bluegroup] = members
    
    # Never return an object in the cache in case the receive of the data modifies the result
    return members.map {|e| e.dup}
  end
  
  def get_person(dn)
    uid = /uid=([^,]+),/.match(dn)[1]
    filter = Net::LDAP::Filter.eq("uid", uid)
    if person = @ldap.search(:base => @config['bluepages_base'], :filter => filter, :attributes => ['cn', 'mail', 'jobresponsibilities', 'manager'])
      common_name = person[0]['cn'][0]
      mail = person[0]['mail'][0]
      job_responsibility = person[0]['jobresponsibilities'][0]
      manager = person[0]['manager'][0]
    else
      common_name = 'unknown'
      mail = 'unknown'
      job_responsibility = 'unknown'
      manager = 'unknown'
    end
    return [common_name, mail, job_responsibility, manager]
  end

  ##########
  private
  ##########

  def self.ldap_config
    if !defined?(@@bluegroups_config) || @@bluegroups_config.nil?
      ldap_filename = File.join(RAILS_ROOT, "config", "ldap.yml")
      config_file = YAML::load(ERB.new(IO.read(ldap_filename)).result)
      @@bluegroups_config = config_file#[RAILS_ENV]
    end
    return @@bluegroups_config
  end

end
