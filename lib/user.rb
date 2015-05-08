class User

  # a group should have a geo or an org but not both
  # a cagegory requires an org, but not vice versa

  def initialize(userid, bluegroups)
    RAILS_DEFAULT_LOGGER.debug "User#initialize userid: #{userid}"
    RAILS_DEFAULT_LOGGER.debug "User#initialize bluegroups: #{bluegroups.join(", ")}"
    # Save the userid
    @userid = userid
    # Save the list of bluegroups that the user is part of
    @blue_groups_list = bluegroups.map {|name| RolesGroup.quote_value(name)}.join(",")
    # Initialize the list of RolesGroup objects to nil -- it will be fetched as needed
    @role_groups = nil
    RAILS_DEFAULT_LOGGER.debug "User#initialize self: #{self.inspect}"    
  end
  
  attr_reader :userid
  
  def roles
    return role_groups.map {|rg| rg.role_name}.uniq
  end

  def is_user_in_role?(role_name)
    return roles.include?(role_name)
  end

  def is_user_in_role_for_org(role_name, org)
    orgs = org_to_str(org)
    role_groups_matching = role_groups.find {|rg| rg.role_name == role_name and "#{rg.org_l1_id},#{rg.org_id}" == org_to_str(org)}
    return !role_groups_matching.nil?
  end
  
  def orgs_for_user
    return role_groups.find_all{|rg| !rg.org_l1_id.nil?}.map {|rg| "#{rg.org_l1_id.to_s},#{rg.org_id.to_s}"}.uniq
  end
  
  # We don't want to save the list of RolesGroups, so these functions are used by Marshal and do not preserve @role_groups.  It will
  # be fetched as needed
  def marshal_dump
    [@userid, @blue_groups_list]
  end
  
  def marshal_load(vars)
    @userid = vars[0]
    @blue_groups_list = vars[1]
    @role_groups = nil
  end
  
  #######
  private
  #######

  def org_to_str(org)
    return org.respond_to?('join') ? org.join(",") : org
  end
  
  def role_groups
    # If we haven't already fetched the list of RolesGroups, do it now
    return [] if @blue_groups_list.empty?
    @role_groups ||= RolesGroup.find(:all, :conditions => "blue_groups_name in (#{@blue_groups_list})")
  end
  
end