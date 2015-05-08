class AccountMemberReport < ScheduledTask

  def self.get_task_objects(config,queued_tasks = [])
    # Save the config for use by other methods
    RAILS_DEFAULT_LOGGER.debug "Setting up config"
    @@config = config

    # Runs on the every day at 3am ET
    schedule_time_utc = ScheduledTask.last_schedule_daily(3,0,false,'Eastern Time (US & Canada)')
    return [self.new("AccountMemberReport",schedule_time_utc, 'y',nil)]
  end

  attr_reader :name, :last_run_timestamp, :auto_retry, :queued_task_id
  
  def initialize(name, last_run_timestamp, auto_retry,queued_task_id)
    # name is a string, last_run_timestamp can either be a Time object, or a string denoting a time
    @name = name
    @last_run_timestamp = last_run_timestamp
    @auto_retry = auto_retry
  end

  def run
    members = []
    orgs = Org.service_hip
    ldap_group_search = LdapGroupSearch.new
    orgs.each do |org|
      #if org.org_name=="Case New Holland"
      rolesgroups = org.roles_groups.all(:select=>"distinct blue_groups_name, role_name",:order=>:blue_groups_name)
      rolesgroups.each do |group|
        #members =
        members.concat(ldap_group_search.fetch_blue_group_members(group.blue_groups_name).map{|m|
          m[4] = org.org_name
          m[5] = group.role_name
          m
          })
      end
      #end
    end
  
    #generate the csv for each hc_group
    csv_report(members)

    {:success => true}
  end


  def csv_report(members)
    filename="#{RAILS_ROOT}/reports/Account_Members.csv"
    CSV.open(filename, 'wb') do |csv|

      csv << ["TITLE: Account Access List"]
      csv << ["Report Run Date: #{Time.now.strftime("%m/%d/%Y %H:%M")} UTC"]
      csv << [nil] # create new line
      # create headers
      csv << [
        "Account",
        "Name",
        "Job Responsibility",
        "EMail",
        "BlueGroup",
        "Role",
     ]
      members.each do |member|
       (person_name, email_address, bluegroup_name, job_responsibility, account_name, role_name) = member
        csv << [
          account_name,
          person_name.upcase,
          job_responsibility || '',
          email_address,
          bluegroup_name,
          role_name,
        ]
      end
    end
  end


end
