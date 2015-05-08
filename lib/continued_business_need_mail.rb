class ContinuedBusinessNeedMail < ScheduledTask

    def self.get_task_objects(config = {}, queued_tasks = [])
        @@config = config
        tasks = []
        jobs = TaskStatus.all(:conditions => "task_status = 'queued' and class_name='ContinuedBusinessNeedMail'",
          :order=>:scheduled_timestamp)
        RAILS_DEFAULT_LOGGER.debug "ContinuedBusinessNeedMail.get_task_objects:  jobs:  #{jobs.inspect}"
        jobs.each do |t|
          tasks << self.new(t.task_name,Time.now.utc, 'n', t.id, t.params)
        end
        return tasks
    end

    attr_reader :name, :last_run_timestamp, :auto_retry, :queued_task_id

    def initialize(name, last_run_timestamp, auto_retry, queued_task_id, params)
        @name = name
        @last_run_timestamp = last_run_timestamp
        @auto_retry = auto_retry
        @queued_task_id = queued_task_id
        @submitter = JSON.parse(params)['u']
    end

    def run
    
        mailing_list = self.class.get_manager_list()

        # Send the e-mails
        if @@config[:send_email]
            mailing_list.keys.sort.each do |manager_email_address|
                manager_name = mailing_list[manager_email_address][:manager_name]
                userids = mailing_list[manager_email_address][:managers_people]
                due_date = Time.now.utc + APP['cbn_email_days_to_respond'].days
                send_to = APP['cbn_email_test_send_all_to'] || manager_email_address
                if APP['cbn_email_test_only_for_manager'].nil? || manager_email_address == APP['cbn_email_test_only_for_manager']
                    HipMailer.deliver_cbn_notice(send_to, APP['cbn_email_respond_address'], APP['cbn_email_subject'], due_date, userids)
                end
            end
        end
        
        HipMailer.deliver_offline_message(@submitter, @@config[:hip_administrator], "CBN emails sent", "CBN emails sent")

        return {:success => true}

    end

    def self.get_manager_list

        people_with_access = []
        # each person will be an array with at least the folloing 5 elements:
        # name
        # email_address,
        # bluegroup,
        # job_responsibility
        # manager ds
        
        RolesGroup.delete_orphaned

        # Get list of active bluegroups
        bluegroup_names = RolesGroup.find(:all, :select => 'distinct blue_groups_name').map {|g| g.blue_groups_name}
        ldap_group_search = LdapGroupSearch.new
        bluegroup_names.each do |bluegroup_name|
            people_with_access.concat(ldap_group_search.fetch_blue_group_members(bluegroup_name))
        end
        
        # Find each person's manager
        mail_list = {}
        people_with_access.each do |person|
            (name, email_address, bluegroup_name, job_responsibility, manager_ds) = person
            (manager_name, manager_email_address) = ldap_group_search.get_person(manager_ds)
            if mail_list.has_key? manager_email_address
                if ! mail_list[manager_email_address][:managers_people].has_key? email_address
                    mail_list[manager_email_address][:managers_people][email_address] = name
                end
            else
                mail_list[manager_email_address] = {
                    :manager_name => manager_name,
                    :managers_people => {email_address => name}
                }
            end
        end

        return mail_list
    end

end