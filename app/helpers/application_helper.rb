# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def flash_content_for(which)
    if flash[which]
      content_tag('p', flash[which], :class => which.to_s, :onclick => 'Effect.Fade(this)')
    end
  end
  
  def set_focus_to_id(id)
    javascript_tag("$('#{id}').focus()");
  end

  def show_current_org_name
    name ||= current_org_name!=nil ? current_org_name : "None Selected"
    "<span style=\"font-weight:bold\">Account</span>: #{name}"
  end

#def button_tag(text, options={})
#   content_tag(:button, {:type =>"button"}.merge(options)) {text}
#end

  def is_admin?
    user ||= session[:credential]? session[:credential][:user] : nil
    #user=session[:credential][:user] if
    user.is_user_in_role?('Admin') if user
  end
  
  # helper for select_tag  list.
  # because of composite_primary_key and association
  # couldn't build named scope with lambda args.
  def hc_group_list(id)
    org=Org.find(id)
    org.hc_groups.group_list
  end

  # all health check groups for the account
  def hc_group_list_all(id)
    org=Org.find(id)
    org.hc_groups.all(:order=>'group_name')
  end

  def exception_list(id)
    org = Org.find(id)
    (org_l1_id, org_id) = org.id
    Suppression.exception_list.find(:all, :conditions => "(org_l1_id, org_id) = (#{org_l1_id}, #{org_id})")
  end

  def exception_list_all(id)
    org = Org.find(id)
    (org_l1_id, org_id) = org.id
    Suppression.find(:all, :conditions => "(org_l1_id, org_id) = (#{org_l1_id}, #{org_id})")
  end

  # select list for per_page drop list on filter pages
  def per_page_list
    [["10"], ["25"],["50"],["100"],["200"]]
  end

  def in_cycle_scan_types
    [["All","all"],["HC Cycle",'HC Cycle'],['unlabeled','unlabeled']]
  end

#  def dashboard_form_for(name, *args, &block)
#    options = args.extract_options!
#    form_for(name, *(args << options.merge(:builder => DashBoardFormBuilder)), &block)
#  end

  # create a groupped array for ooc scan_types.
  # the ---------- is a seperator between group scan_types.
  def ooc_scan_type_list(gui_active_only = false)
    scan_types =OocScanType.find_by_sql("select ooc_scan_type
            from hip_ooc_scan_type_v #{"where active_in_gui = 'y'" if gui_active_only}
            group by grouping sets ((ooc_scan_type, ooc_group_type),(ooc_group_type))
            order by ooc_group_type, ooc_scan_type")
    array=[]
    scan_types.each do |type|
      array.push(type['ooc_scan_type']) unless type['ooc_scan_type'].blank?
      array.push('--------------') if type['ooc_scan_type'].blank?
    end
    array.pop # remove the last blank line
    return array
  end

  # display system messages to the use.  See the Admin/Config page
  # available params.
  def system_msg
    msg=[]
    if (AppConfig.read_only_flag=='y' and !AppConfig.read_only_msg.blank?)
      msg << "<p>#{h AppConfig.read_only_msg}</p>"
    end
    
    if (AppConfig.ooc_read_only_flag=='y' and !AppConfig.ooc_read_only_msg.blank?)
      msg << "<p>#{h AppConfig.ooc_read_only_msg}</p>"
    end
    
    unless AppConfig.hip_notice.nil?
      msg << "<p>#{h AppConfig.hip_notice}</p>"
    end
    msg.join('')
  end

  # display a controller specific message
  def controller_msg
    RAILS_DEFAULT_LOGGER.debug("@controller.class.name: #{@controller.class.name}")
    msg = AppConfig.hip_controller_notice(@controller.class.name) || ''
    msg = "<p>#{h msg}</p>" unless msg.empty?
    msg
  end

  # does not show deleted
  def ooc_group_list_all(id,group_type=nil)
    org = Org.find(id)
    group_type_cond = group_type.nil? ? nil:"AND ooc_group_type='#{group_type}'"
    org.ooc_groups.all(:conditions=>"ooc_group_status!='deleted' #{group_type_cond}",:order=>'ooc_group_type,ooc_group_name')
  end

  # only shows active
  def ooc_group_list_active(id)
    org = Org.find(id)
    org.ooc_groups.all(:conditions=>"ooc_group_status='active'",:order=>'ooc_group_name')
  end
  
  def ooc_group_status_list
    ['active', 'inactive']
  end

  def all_groups_list
    (org_l1_id,org_id)=current_org_id.split(",")
    SwareBase.find_by_sql("with union as (
      select group_name,hg.hc_group_id as group_id,'HC Cycle'as group_type,count(ag.asset_id)as count from hip_hc_group_v hg
      join hip_asset_group_v as ag on ag.hc_group_id=hg.hc_group_id
      join dim_comm_tool_asset_hist_v ah on ah.tool_asset_id=ag.asset_id
        and CURRENT_TIMESTAMP BETWEEN ah.row_from_timestamp AND
        COALESCE(ah.row_to_timestamp, CURRENT_TIMESTAMP) and ah.system_status!='decom'
      where hg.org_l1_id=#{org_l1_id} and hg.org_id=#{org_id}
      group by group_name,hg.hc_group_id
        union
      select  ooc_group_name,g.ooc_group_id,ooc_group_type,count(ag.asset_id)as count from hip_ooc_group_v  as g
      join hip_ooc_asset_group_v as ag on ag.ooc_group_id=g.ooc_group_id
      join dim_comm_tool_asset_hist_v ah on ah.tool_asset_id=ag.asset_id
        and CURRENT_TIMESTAMP BETWEEN ah.row_from_timestamp AND
        COALESCE(ah.row_to_timestamp, CURRENT_TIMESTAMP) and ah.system_status!='decom'
      where  g.org_l1_id=#{org_l1_id} and g.org_id=#{org_id}
      group by ooc_group_name,g.ooc_group_id,ooc_group_type
      )
      select * from union
      order by group_type,group_name")
  end

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)",:title=>"Remove Row")
  end

  def link_to_add_fields(name, f, association )
    #$stderr.puts "association #{association}"
    new_object = f.object.class.reflect_on_association(association).klass.new
    #$stderr.puts "new_object #{new_object.attributes}"
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    #$stderr.puts "fields #{fields}"
    # $stderr.puts "fields2 #{escape_javascript(fields)}"
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"))
  end

  def expired_suppressions
    (org_l1_id,org_id) = current_org_id.split(",")
    expired = Suppression.find(:all,
      :conditions=>"org_id=#{org_id} and org_l1_id=#{org_l1_id}  and end_timestamp < current_timestamp",
      :order=>:suppress_name)
    expired
  end
  def expiring_suppressions
    (org_l1_id,org_id) = current_org_id.split(",")  
    expired = Suppression.find(:all,
      :conditions=>"org_id=#{org_id} and org_l1_id=#{org_l1_id} and 
      end_timestamp between current_timestamp and current_timestamp + 3 months",
      :order=>:suppress_name)
    expired
  end
end
