# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "consdb_fw_dev_dir_act_monthly", :id => false, :force => true do |t|
    t.integer "device_date_id",               :null => false
    t.integer "device_id",                    :null => false
    t.integer "direction_id",                 :null => false
    t.integer "action_id",                    :null => false
    t.integer "event_cnt",      :limit => 19, :null => false
  end

  add_index "consdb_fw_dev_dir_act_monthly", ["device_date_id"], :name => "sql120109175244830"
  add_index "consdb_fw_dev_dir_act_monthly", ["device_id"], :name => "consdb_fw_ddam_x1"

  create_table "consdb_fw_dev_dir_act_proto_port_monthly", :id => false, :force => true do |t|
    t.integer "device_date_id",               :null => false
    t.integer "device_id",                    :null => false
    t.integer "direction_id",                 :null => false
    t.integer "action_id",                    :null => false
    t.integer "protocol_id",                  :null => false
    t.integer "port",                         :null => false
    t.integer "event_cnt",      :limit => 19, :null => false
  end

  add_index "consdb_fw_dev_dir_act_proto_port_monthly", ["device_date_id"], :name => "sql120109175245100"
  add_index "consdb_fw_dev_dir_act_proto_port_monthly", ["device_id"], :name => "consdb_fw_ddappm_x1"

  create_table "consdb_ids_dev_sig_act_monthly", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "device_id",      :null => false
    t.integer "sig_id",         :null => false
    t.integer "action_id",      :null => false
    t.integer "event_cnt",      :null => false
  end

  add_index "consdb_ids_dev_sig_act_monthly", ["device_date_id"], :name => "sql120109175244640"
  add_index "consdb_ids_dev_sig_act_monthly", ["device_id"], :name => "consdb_ids_dsam_x1"
  add_index "consdb_ids_dev_sig_act_monthly", ["sig_id"], :name => "consdb_ids_dsam_x2"

  create_table "consdb_ids_dev_sig_act_monthly2", :id => false, :force => true do |t|
    t.integer "device_date_id",               :null => false
    t.integer "device_id",                    :null => false
    t.integer "sig_id",                       :null => false
    t.integer "action_id",                    :null => false
    t.integer "event_cnt",      :limit => 19, :null => false
  end

  add_index "consdb_ids_dev_sig_act_monthly2", ["device_date_id"], :name => "sql120109175246030"
  add_index "consdb_ids_dev_sig_act_monthly2", ["device_id"], :name => "consdb_ids_dsam2_x1"
  add_index "consdb_ids_dev_sig_act_monthly2", ["sig_id"], :name => "consdb_ids_dsam2_x2"

  create_table "dim_comm_action", :primary_key => "action_id", :force => true do |t|
    t.string "action_name",     :limit => 20,  :null => false
    t.string "action_category", :limit => 20,  :null => false
    t.string "action_desc",     :limit => 254
  end

  create_table "dim_comm_asset", :primary_key => "asset_id", :force => true do |t|
    t.integer   "org_l1_id"
    t.integer   "org_id",                                      :null => false
    t.string    "encryption_flag",             :limit => 1,    :null => false
    t.string    "asset_type",                  :limit => 20,   :null => false
    t.string    "asset_criticality",           :limit => 20,   :null => false
    t.string    "host_name",                   :limit => 254
    t.string    "domain_name",                 :limit => 254
    t.string    "qualified_host_name",         :limit => 254
    t.string    "asset_desc",                  :limit => 1000
    t.string    "support_tower",               :limit => 20
    t.timestamp "asset_lu_timestamp"
    t.string    "internet_acc_flag",           :limit => 1
    t.integer   "no_port_media"
    t.string    "partition_name",              :limit => 20
    t.timestamp "install_date"
    t.timestamp "sunset_date"
    t.string    "etl_src_sys_name",            :limit => 50
    t.string    "etl_src_sys_id",              :limit => 50
    t.string    "highest_class_name",          :limit => 60
    t.string    "src_sys_name",                :limit => 60
    t.string    "status_name",                 :limit => 30
    t.string    "status_type",                 :limit => 30
    t.string    "vendor_short_name",           :limit => 20
    t.string    "os_short_name",               :limit => 20
    t.string    "os_name",                     :limit => 100
    t.string    "os_version",                  :limit => 10
    t.string    "os_release",                  :limit => 10
    t.string    "os_patch_level",              :limit => 20
    t.string    "os_modification_level",       :limit => 10
    t.string    "room_name",                   :limit => 75
    t.string    "room_description",            :limit => 75
    t.string    "room_ca_level",               :limit => 10
    t.string    "room_floor",                  :limit => 25
    t.string    "building_code",               :limit => 20
    t.string    "building_address1",           :limit => 50
    t.string    "building_address2",           :limit => 50
    t.string    "building_address3",           :limit => 50
    t.string    "building_postal_code",        :limit => 80
    t.string    "site_name",                   :limit => 50
    t.integer   "site_account_id",             :limit => 19
    t.string    "city_name",                   :limit => 75
    t.string    "state_province_short_name",   :limit => 25
    t.string    "state_province_name",         :limit => 75
    t.string    "country_short_name",          :limit => 25
    t.string    "country_name",                :limit => 75
    t.integer   "secmart_encrypt_key_version",                 :null => false
    t.timestamp "secmart_lu_timestamp",                        :null => false
    t.string    "ip_string_list",              :limit => 1000
  end

  add_index "dim_comm_asset", ["host_name"], :name => "dim_comm_asset_x3"
  add_index "dim_comm_asset", ["org_id"], :name => "dim_comm_asset_x1"
  add_index "dim_comm_asset", ["org_l1_id"], :name => "dim_comm_asset_x2"
  add_index "dim_comm_asset", ["qualified_host_name"], :name => "dim_comm_asset_x4"

  create_table "dim_comm_asset_conn", :primary_key => "asset_id", :force => true do |t|
    t.integer   "org_l1_id"
    t.integer   "org_id",                                     :null => false
    t.string    "connection_name",              :limit => 40, :null => false
    t.string    "ip_string",                    :limit => 40, :null => false
    t.string    "netmask_string",               :limit => 40
    t.string    "net_adapt_name",               :limit => 20
    t.string    "net_adapt_purp_name",          :limit => 40
    t.string    "net_name",                     :limit => 40
    t.string    "net_ip_string",                :limit => 40
    t.string    "net_netmask_string",           :limit => 40
    t.string    "net_derrived_start_ip_string", :limit => 40
    t.string    "net_derrived_stop_ip_string",  :limit => 40
    t.string    "net_function",                 :limit => 20
    t.string    "net_shared_flag",              :limit => 3
    t.string    "net_ibm_shared_flag",          :limit => 3
    t.timestamp "secmart_lu_timestamp",                       :null => false
  end

  add_index "dim_comm_asset_conn", ["ip_string"], :name => "dim_comm_asset_conn_x3"
  add_index "dim_comm_asset_conn", ["org_id"], :name => "dim_comm_asset_conn_x1"
  add_index "dim_comm_asset_conn", ["org_l1_id"], :name => "dim_comm_asset_conn_x2"

  create_table "dim_comm_asset_org", :primary_key => "org_id", :force => true do |t|
    t.string    "encryption_required_flag",    :limit => 1,                               :null => false
    t.integer   "secmart_encrypt_key_version"
    t.string    "asset_data_current_flag",     :limit => 1,                               :null => false
    t.timestamp "lu_timestamp",                                                           :null => false
    t.string    "lu_userid",                   :limit => 128, :default => "CURRENT_USER", :null => false
  end

  create_table "dim_comm_batch", :id => false, :force => true do |t|
    t.string    "subject",            :limit => 20
    t.string    "name",               :limit => 20
    t.string    "activity",           :limit => 20
    t.integer   "transform_batch_id", :limit => 19
    t.integer   "load_batch_id",      :limit => 19
    t.timestamp "lu_timestamp"
  end

  add_index "dim_comm_batch", ["load_batch_id"], :name => "dim_comm_bat_x2"
  add_index "dim_comm_batch", ["transform_batch_id"], :name => "dim_comm_bat_x1"

  create_table "dim_comm_cat", :primary_key => "cat_id", :force => true do |t|
    t.string "cat_name", :limit => 20,  :null => false
    t.string "cat_desc", :limit => 254
  end

  create_table "dim_comm_date", :primary_key => "date_id", :force => true do |t|
    t.date      "date"
    t.integer   "year_id"
    t.integer   "year"
    t.integer   "quarter_id"
    t.integer   "quarter_of_year"
    t.integer   "month_id"
    t.string    "month_name",       :limit => 10
    t.integer   "month_of_year"
    t.integer   "month_of_quarter"
    t.integer   "week_id"
    t.integer   "weekiso_id"
    t.integer   "week_of_year"
    t.integer   "weekiso_of_year"
    t.integer   "week_of_quarter"
    t.integer   "week_of_month"
    t.integer   "day_id"
    t.integer   "day_of_month"
    t.integer   "day_of_week"
    t.integer   "day_of_year"
    t.string    "day_name",         :limit => 10
    t.string    "day_weekend_flag", :limit => 1
    t.string    "day_weekpart",     :limit => 7
    t.integer   "day_epoch_start"
    t.integer   "day_epoch_stop"
    t.string    "lu_userid",        :limit => 20, :null => false
    t.timestamp "lu_timestamp",                   :null => false
  end

  create_table "dim_comm_device", :primary_key => "device_id", :force => true do |t|
    t.string  "device_hostname",       :limit => 120
    t.string  "device_ip_string",      :limit => 20
    t.string  "device_source_id",      :limit => 60
    t.string  "device_source_os_name", :limit => 40
    t.integer "org_l1_id",                            :null => false
    t.integer "org_id",                               :null => false
    t.string  "org_source_id",         :limit => 60
  end

  create_table "dim_comm_device_mss", :primary_key => "device_id", :force => true do |t|
    t.string  "device_hostname",                   :limit => 120
    t.string  "device_ip_string",                  :limit => 20
    t.string  "device_source_id",                  :limit => 60
    t.string  "device_source_os_name",             :limit => 40
    t.integer "org_l1_id",                                                                                          :null => false
    t.integer "org_id",                                                                                             :null => false
    t.string  "org_source_id",                     :limit => 60
    t.string  "source_dev_id",                     :limit => 40
    t.string  "source_dev_cust_device_name",       :limit => 120
    t.string  "source_dev_machine_host_name",      :limit => 120
    t.string  "source_dev_machine_platform",       :limit => 40
    t.string  "source_dev_cust_id",                :limit => 20
    t.string  "source_dev_status",                 :limit => 60
    t.string  "source_dev_service_name",           :limit => 60
    t.string  "source_dev_manufacturer",           :limit => 60
    t.string  "source_dev_software_version",       :limit => 60
    t.string  "source_dev_sensor_type",            :limit => 40
    t.string  "source_dev_primary_function",       :limit => 80
    t.string  "source_dev_primary_application",    :limit => 80
    t.string  "source_dev_ids_config_type",        :limit => 40
    t.string  "source_dev_network_seg_type",       :limit => 40
    t.string  "source_dev_inline_appliance_mode",  :limit => 40
    t.string  "source_dev_stacked_flag",           :limit => 3
    t.string  "source_dev_managed_by",             :limit => 40
    t.string  "source_dev_monitored_by",           :limit => 15
    t.string  "source_dev_cluster_fw_name",        :limit => 60
    t.string  "source_dev_ids_config_type2",       :limit => 60
    t.string  "source_dev_fw_type_and_ver",        :limit => 60
    t.string  "source_dev_default_gateway",        :limit => 120
    t.string  "source_dev_ip_ext_string",          :limit => 20
    t.string  "source_dev_os_name",                :limit => 60
    t.string  "source_dev_nlr_threshold",          :limit => 60
    t.string  "source_dev_poll_period",            :limit => 40
    t.string  "source_dev_site_name",              :limit => 120
    t.string  "source_dev_site_id",                :limit => 40
    t.string  "source_dev_data_retention_period",  :limit => 40
    t.string  "source_dev_index_retention_period", :limit => 40
    t.string  "source_dev_timezone",               :limit => 60
    t.string  "source_cust_id",                    :limit => 20
    t.string  "source_cust_name",                  :limit => 80
    t.string  "source_cust_partner_id",            :limit => 20
    t.string  "source_cust_partner_name",          :limit => 80
    t.string  "source_cust_category",              :limit => 60
    t.string  "source_cust_industry",              :limit => 120
    t.string  "source_cust_regulated",             :limit => 10
    t.string  "source_cust_mids",                  :limit => 10
    t.integer "source_cust_num_ids"
    t.string  "source_cust_mps",                   :limit => 10
    t.string  "source_cust_mfs",                   :limit => 10
    t.integer "source_cust_num_fw"
    t.string  "source_cust_selm",                  :limit => 10
    t.string  "source_cust_vms",                   :limit => 10
    t.integer "source_cust_num_ext_ip"
    t.integer "source_cust_num_int_ip"
    t.integer "source_cust_num_scanners"
    t.string  "source_cust_lms",                   :limit => 10
    t.string  "source_cust_eam",                   :limit => 10
    t.integer "source_cust_num_devices"
    t.string  "source_cust_third_party",           :limit => 10
    t.string  "source_cust_service_name",          :limit => 60
    t.string  "source_cust_sia",                   :limit => 10
    t.string  "source_cust_sia_name",              :limit => 60
    t.string  "source_cust_pci_dss",               :limit => 10
    t.string  "source_cust_hipaa",                 :limit => 10
    t.string  "source_cust_glba",                  :limit => 10
    t.decimal "source_cust_mrr",                                  :precision => 10, :scale => 2
    t.string  "source_cust_status",                :limit => 20
    t.integer "industry_id",                                                                     :default => 0,     :null => false
    t.string  "ind_section_cd",                    :limit => 1,                                  :default => "0",   :null => false
    t.string  "ind_section_name",                  :limit => 200,                                :default => "unk", :null => false
    t.string  "ind_section_short_name",            :limit => 40,                                 :default => "unk", :null => false
    t.integer "ind_division_cd",                                                                 :default => 0,     :null => false
    t.string  "ind_division_name",                 :limit => 200,                                :default => "unk", :null => false
    t.string  "ind_division_short_name",           :limit => 40,                                 :default => "unk", :null => false
    t.string  "cons_db_ip_string",                 :limit => 20
    t.string  "cons_db_hostname",                  :limit => 80
    t.string  "fw_db_ip_string",                   :limit => 20
    t.string  "fw_db_hostname",                    :limit => 80
    t.string  "lms_agg_ip_string",                 :limit => 20
    t.string  "lms_agg_hostname",                  :limit => 80
  end

  create_table "dim_comm_direction", :primary_key => "direction_id", :force => true do |t|
    t.string "direction_name", :limit => 20, :null => false
  end

  create_table "dim_comm_industry", :primary_key => "industry_id", :force => true do |t|
    t.string "industry_name", :limit => 30,  :null => false
    t.string "industry_desc", :limit => 254
  end

  add_index "dim_comm_industry", ["industry_name"], :name => "dim_comm_ind_uk1", :unique => true

  create_table "dim_comm_org", :primary_key => "org_l1_id", :force => true do |t|
    t.integer   "org_id",                             :null => false
    t.string    "org_name",             :limit => 80, :null => false
    t.string    "org_type",             :limit => 20, :null => false
    t.integer   "org_level",                          :null => false
    t.integer   "org_vreg_id"
    t.string    "org_ecm_account_id",   :limit => 20
    t.string    "org_ecm_account_name", :limit => 80
    t.string    "org_ecm_account_type", :limit => 20
    t.integer   "org_primary_owner_id"
    t.integer   "org_backup_owner_id"
    t.integer   "org_parent_id"
    t.string    "org_l1_name",          :limit => 80, :null => false
    t.string    "org_l1_name_tiny",     :limit => 20
    t.string    "org_l1_name_short",    :limit => 30
    t.string    "org_l1_name_vreg",     :limit => 46
    t.string    "org_l1_type",          :limit => 20, :null => false
    t.integer   "org_l1_vreg_id"
    t.integer   "org_l1_rtid_id"
    t.integer   "org_l2_id"
    t.string    "org_l2_name",          :limit => 80
    t.string    "org_l2_type",          :limit => 20
    t.integer   "org_l2_vreg_id"
    t.integer   "org_l3_id"
    t.string    "org_l3_name",          :limit => 80
    t.string    "org_l3_type",          :limit => 20
    t.integer   "org_l4_id"
    t.string    "org_l4_name",          :limit => 80
    t.string    "org_l4_type",          :limit => 20
    t.integer   "org_l5_id"
    t.string    "org_l5_name",          :limit => 80
    t.string    "org_l5_type",          :limit => 20
    t.string    "org_status",           :limit => 10
    t.integer   "org_industry_id"
    t.string    "org_industry_name",    :limit => 30
    t.integer   "org_country_id"
    t.string    "org_country_name",     :limit => 80
    t.string    "org_ecm_instance",     :limit => 20
    t.string    "org_service_ecm",      :limit => 1
    t.string    "org_service_vuln",     :limit => 1
    t.string    "org_service_health",   :limit => 1
    t.timestamp "lu_timestamp"
    t.string    "lu_operation",         :limit => 20
    t.string    "org_service_hip",      :limit => 1
  end

  create_table "dim_comm_org_ids", :primary_key => "org_id", :force => true do |t|
    t.timestamp "lu_timestamp"
  end

  create_table "dim_comm_org_l1", :primary_key => "org_l1_id", :force => true do |t|
    t.timestamp "lu_timestamp"
  end

  create_table "dim_comm_os", :primary_key => "os_id", :force => true do |t|
    t.string "os_type",     :limit => 20, :null => false
    t.string "os_product",  :limit => 20, :null => false
    t.string "vendor_name", :limit => 40, :null => false
    t.string "os_name",     :limit => 40, :null => false
    t.string "os_ver",      :limit => 40, :null => false
  end

  add_index "dim_comm_os", ["os_type", "os_name", "os_ver"], :name => "dim_comm_os_uk1", :unique => true

  create_table "dim_comm_port", :primary_key => "port", :force => true do |t|
    t.string    "port_category", :limit => 20,   :null => false
    t.string    "service_list",  :limit => 2000
    t.integer   "service_cnt",                   :null => false
    t.string    "malware_list",  :limit => 2000
    t.integer   "malware_cnt",                   :null => false
    t.string    "lu_userid",     :limit => 20,   :null => false
    t.timestamp "lu_timestamp",                  :null => false
  end

  create_table "dim_comm_port_protocol_soft", :primary_key => "port", :force => true do |t|
    t.string "protocol",     :limit => 10,  :null => false
    t.string "type",         :limit => 10,  :null => false
    t.string "name",         :limit => 64,  :null => false
    t.string "desc",         :limit => 254
    t.string "primary_flag", :limit => 1
    t.string "source",       :limit => 10,  :null => false
  end

  add_index "dim_comm_port_protocol_soft", ["name"], :name => "dim_comm_port_pps_x1"

  create_table "dim_comm_protocol", :primary_key => "protocol_id", :force => true do |t|
    t.string "protocol_name", :limit => 40, :null => false
  end

  create_table "dim_comm_score", :primary_key => "score_id", :force => true do |t|
    t.integer   "score_parent_id"
    t.string    "score_name",             :limit => 40,   :null => false
    t.string    "score_code_name",        :limit => 40,   :null => false
    t.string    "score_code_type",        :limit => 40,   :null => false
    t.string    "score_engine",           :limit => 20,   :null => false
    t.string    "score_type",             :limit => 20,   :null => false
    t.string    "score_summary_type",     :limit => 20
    t.float     "score_summary_weight"
    t.string    "score_desc",             :limit => 254
    t.string    "score_desc_long",        :limit => 4000
    t.string    "score_url",              :limit => 200
    t.string    "subject_name",           :limit => 20,   :null => false
    t.string    "subject_aspect",         :limit => 20,   :null => false
    t.integer   "subject_level",                          :null => false
    t.integer   "subject_retention_days",                 :null => false
    t.timestamp "lu_timestamp",                           :null => false
    t.string    "lu_userid",              :limit => 20,   :null => false
  end

  add_index "dim_comm_score", ["subject_name", "subject_aspect", "score_name"], :name => "dim_comm_score_uk2", :unique => true

  create_table "dim_comm_severity", :primary_key => "severity_id", :force => true do |t|
    t.string "severity_cd",   :limit => 10,  :null => false
    t.string "severity_desc", :limit => 254
  end

  add_index "dim_comm_severity", ["severity_cd"], :name => "dim_severity_uk1", :unique => true

  create_table "dim_comm_sig", :primary_key => "sig_id", :force => true do |t|
    t.string "sig_title",  :limit => 254, :null => false
    t.string "sig_source", :limit => 60,  :null => false
  end

  create_table "dim_comm_software", :primary_key => "software_id", :force => true do |t|
    t.string    "vendor_name",         :limit => 40,  :null => false
    t.string    "vendor_short_name",   :limit => 20,  :null => false
    t.string    "software_name",       :limit => 30,  :null => false
    t.string    "software_short_name", :limit => 20,  :null => false
    t.string    "version",             :limit => 10,  :null => false
    t.string    "release",             :limit => 10,  :null => false
    t.string    "patch_level",         :limit => 10,  :null => false
    t.string    "remark",              :limit => 200
    t.string    "modification_level",  :limit => 10,  :null => false
    t.timestamp "lu_timestamp",                       :null => false
    t.string    "lu_userid",           :limit => 20,  :null => false
  end

  add_index "dim_comm_software", ["software_name", "version", "release", "patch_level", "modification_level"], :name => "dim_comm_soft_uk1", :unique => true

  create_table "dim_comm_tool", :primary_key => "tool_id", :force => true do |t|
    t.string "tool_name",    :limit => 20, :null => false
    t.string "manager_name", :limit => 20, :null => false
    t.string "hc_type",      :limit => 1,  :null => false
    t.string "vuln_type",    :limit => 1,  :null => false
    t.string "patch_type",   :limit => 1,  :null => false
    t.string "ids_type",     :limit => 1,  :null => false
    t.string "fw_type",      :limit => 1,  :null => false
    t.string "asset_type",   :limit => 1,  :null => false
  end

  add_index "dim_comm_tool", ["tool_name", "manager_name"], :name => "dim_commtool_uk1", :unique => true

  create_table "dim_comm_tool_asset", :primary_key => "tool_asset_id", :force => true do |t|
    t.integer   "org_l1_id",                                                   :null => false
    t.integer   "manager_id"
    t.string    "source_asset_id",           :limit => 60,                     :null => false
    t.string    "source_org_id",             :limit => 60
    t.string    "ip_string",                 :limit => 20
    t.integer   "ip_int",                    :limit => 19
    t.string    "host_name",                 :limit => 80
    t.string    "os_source_text",            :limit => 40,                     :null => false
    t.string    "tool",                      :limit => 20, :default => "itim"
    t.integer   "org_id",                                  :default => 0
    t.integer   "os_id",                                   :default => 0
    t.timestamp "last_tool_login_timestamp"
    t.timestamp "lu_timestamp"
    t.string    "lu_userid",                 :limit => 20, :default => "unk"
  end

  create_table "dim_comm_tool_asset_cat", :primary_key => "tool_asset_id", :force => true do |t|
    t.integer   "org_l1_id",                   :null => false
    t.integer   "org_id",                      :null => false
    t.integer   "manager_id",                  :null => false
    t.string    "category",     :limit => 100, :null => false
    t.string    "lu_userid",    :limit => 20,  :null => false
    t.timestamp "lu_timestamp",                :null => false
  end

  create_table "dim_comm_tool_asset_conn", :primary_key => "tool_asset_id", :force => true do |t|
    t.integer   "org_l1_id",                                                :null => false
    t.integer   "org_id",                                                   :null => false
    t.integer   "network_id"
    t.string    "ip_string",         :limit => 15,                          :null => false
    t.integer   "ip_int",            :limit => 19,                          :null => false
    t.string    "mac_address",       :limit => 24
    t.string    "host_name",         :limit => 80
    t.string    "primary_conn_flag", :limit => 1,   :default => "n",        :null => false
    t.string    "primary_conn_rule", :limit => 8,   :default => "implicit", :null => false
    t.string    "conn_desc",         :limit => 254
    t.string    "lu_userid",         :limit => 20,                          :null => false
    t.timestamp "lu_timestamp",                                             :null => false
  end

  create_table "dim_comm_tool_asset_conn_hist", :primary_key => "tool_asset_id", :force => true do |t|
    t.integer   "org_l1_id",                                                 :null => false
    t.integer   "org_id",                                                    :null => false
    t.timestamp "row_from_timestamp",                                        :null => false
    t.timestamp "row_to_timestamp"
    t.integer   "network_id"
    t.string    "ip_string",          :limit => 40,                          :null => false
    t.string    "ip_int",             :limit => 40,                          :null => false
    t.string    "mac_address",        :limit => 40
    t.string    "host_name",          :limit => 254
    t.string    "primary_conn_flag",  :limit => 1,   :default => "n",        :null => false
    t.string    "primary_conn_rule",  :limit => 8,   :default => "implicit", :null => false
    t.string    "conn_desc",          :limit => 254
    t.string    "lu_userid",          :limit => 20,                          :null => false
    t.timestamp "lu_timestamp",                                              :null => false
  end

  create_table "dim_comm_tool_asset_hist", :primary_key => "tool_asset_vid", :force => true do |t|
    t.integer   "tool_asset_id",                                                  :null => false
    t.timestamp "row_from_timestamp",                                             :null => false
    t.timestamp "row_to_timestamp"
    t.integer   "org_l1_id",                                                      :null => false
    t.integer   "manager_id",                                  :default => 0,     :null => false
    t.string    "source_asset_id",             :limit => 60,                      :null => false
    t.string    "source_org_id",               :limit => 60
    t.string    "ip_string_primary",           :limit => 40
    t.string    "ip_int_primary",              :limit => 40
    t.string    "ip_string_list",              :limit => 1000
    t.string    "host_name",                   :limit => 254
    t.integer   "tool_id",                                                        :null => false
    t.integer   "org_id",                                      :default => 0
    t.integer   "os_id",                                       :default => 0
    t.string    "os_source_text",              :limit => 254
    t.string    "system_status",               :limit => 10,                      :null => false
    t.string    "encryption_flag",             :limit => 1,                       :null => false
    t.timestamp "lu_timestamp"
    t.string    "lu_userid",                   :limit => 20,   :default => "unk"
    t.string    "hc_auto_flag",                :limit => 1,    :default => "u",   :null => false
    t.integer   "hc_auto_interval_weeks"
    t.string    "hc_manual_flag",              :limit => 1
    t.integer   "hc_manual_interval_weeks"
    t.string    "security_policy_name",        :limit => 40
    t.string    "disaster_recovery_flag",      :limit => 1,    :default => "n"
    t.string    "internet_accessible_flag",    :limit => 1,    :default => "n",   :null => false
    t.string    "vital_business_process_flag", :limit => 1,    :default => "n",   :null => false
    t.date      "hc_start_date"
  end

  add_index "dim_comm_tool_asset_hist", ["org_id"], :name => "dim_comm_tah_x1"
  add_index "dim_comm_tool_asset_hist", ["org_l1_id", "tool_id", "manager_id", "source_asset_id", "row_from_timestamp"], :name => "dim_comm_tah_uk1", :unique => true
  add_index "dim_comm_tool_asset_hist", ["tool_asset_id"], :name => "dim_comm_tah_x2"

  create_table "dim_comm_tool_asset_mss", :primary_key => "tool_asset_id", :force => true do |t|
    t.integer   "org_l1_id",                                  :null => false
    t.integer   "org_id",                                     :null => false
    t.string    "nid_service_flag",             :limit => 1
    t.string    "hid_service_flag",             :limit => 1
    t.string    "mode",                         :limit => 10
    t.string    "source_service_name",          :limit => 40
    t.string    "source_manufacturer",          :limit => 80
    t.string    "source_software_ver",          :limit => 80
    t.string    "source_status",                :limit => 20
    t.string    "source_sensor_type",           :limit => 20
    t.string    "source_sensor_type_detail",    :limit => 20
    t.string    "source_machine_platform",      :limit => 80
    t.string    "source_primary_function",      :limit => 80
    t.string    "source_primary_application",   :limit => 80
    t.string    "source_ids_config_type",       :limit => 40
    t.string    "source_network_seg_type",      :limit => 40
    t.string    "source_inline_appliance_mode", :limit => 40
    t.string    "source_stacked_flag",          :limit => 3
    t.string    "source_monitored_by",          :limit => 15
    t.string    "source_ip_ext_string",         :limit => 20
    t.string    "source_os_name",               :limit => 60
    t.string    "source_timezone",              :limit => 60
    t.string    "lu_userid",                    :limit => 20, :null => false
    t.timestamp "lu_timestamp",                               :null => false
  end

  create_table "dim_comm_tool_asset_scan", :primary_key => "tool_asset_id", :force => true do |t|
    t.integer   "org_l1_id",                           :null => false
    t.integer   "org_id",                              :null => false
    t.integer   "tool_id",                             :null => false
    t.integer   "scan_date_id",                        :null => false
    t.timestamp "scan_start_timestamp",                :null => false
    t.timestamp "scan_stop_timestamp",                 :null => false
    t.string    "scan_service",         :limit => 40,  :null => false
    t.integer   "extract_batch_id",     :limit => 19
    t.integer   "transform_batch_id",   :limit => 19
    t.integer   "load_batch_id",        :limit => 19
    t.string    "source_scan_id",       :limit => 40
    t.timestamp "lu_timestamp"
    t.string    "host_status",          :limit => 20
    t.string    "scanner_host_name",    :limit => 100
    t.string    "scan_parms",           :limit => 10
    t.integer   "scan_id"
  end

  add_index "dim_comm_tool_asset_scan", ["org_id"], :name => "dim_comm_tas_x1"
  add_index "dim_comm_tool_asset_scan", ["org_l1_id", "scan_date_id"], :name => "sql120109175236580"
  add_index "dim_comm_tool_asset_scan", ["org_l1_id"], :name => "sql120109175236990"
  add_index "dim_comm_tool_asset_scan", ["scan_date_id"], :name => "sql120109175236980"

  create_table "dim_comm_tool_asset_scan_hist", :primary_key => "asset_id", :force => true do |t|
    t.integer   "org_l1_id",                                              :null => false
    t.integer   "org_id",                                                 :null => false
    t.integer   "tool_id",                                                :null => false
    t.integer   "scan_date_id",                                           :null => false
    t.timestamp "scan_start_timestamp",                                   :null => false
    t.timestamp "scan_stop_timestamp",                                    :null => false
    t.string    "scan_service",         :limit => 40,                     :null => false
    t.integer   "scan_id",                             :default => 0,     :null => false
    t.string    "source_scan_id",       :limit => 40,  :default => "unk", :null => false
    t.string    "host_status",          :limit => 20,  :default => "unk", :null => false
    t.string    "scanner_host_name",    :limit => 254, :default => "unk", :null => false
    t.string    "scan_parms",           :limit => 128, :default => "unk", :null => false
    t.integer   "extract_batch_id",                    :default => 0,     :null => false
    t.integer   "transform_batch_id",                  :default => 0,     :null => false
    t.integer   "load_batch_id",                       :default => 0,     :null => false
    t.timestamp "lu_timestamp",                                           :null => false
  end

  add_index "dim_comm_tool_asset_scan_hist", ["org_id"], :name => "dim_comm_tash_x1"
  add_index "dim_comm_tool_asset_scan_hist", ["org_l1_id"], :name => "sql120109175241230"
  add_index "dim_comm_tool_asset_scan_hist", ["scan_date_id"], :name => "dim_comm_tash_x2"
  add_index "dim_comm_tool_asset_scan_hist", ["scan_id"], :name => "dim_comm_tash_x3", :unique => true

  create_table "dim_comm_tool_asset_soft", :primary_key => "tool_asset_id", :force => true do |t|
    t.integer   "org_l1_id",                    :null => false
    t.integer   "org_id",                       :null => false
    t.integer   "software_id",                  :null => false
    t.string    "component_name", :limit => 20
    t.string    "component_ver",  :limit => 20
    t.string    "content_name",   :limit => 20
    t.string    "content_ver",    :limit => 20
    t.string    "lu_userid",      :limit => 20, :null => false
    t.timestamp "lu_timestamp",                 :null => false
  end

  create_table "dim_comm_vuln", :primary_key => "vuln_id", :force => true do |t|
    t.string  "title",                       :limit => 200
    t.integer "vuln_release_date"
    t.integer "risk_type_id"
    t.string  "risk_type_name",              :limit => 80
    t.integer "risk_type_ord"
    t.integer "rating_id"
    t.string  "rating_name",                 :limit => 80
    t.integer "reported_ver"
    t.integer "fixed_ver"
    t.integer "types_id"
    t.string  "types_name",                  :limit => 40
    t.integer "ref_id"
    t.string  "ref_name",                    :limit => 200
    t.string  "ref_title",                   :limit => 200
    t.string  "ref_summary",                 :limit => 1000
    t.string  "ref_info",                    :limit => 4096
    t.string  "ref_verify",                  :limit => 4096
    t.string  "ref_fix",                     :limit => 4096
    t.string  "ref_nsa_file_name",           :limit => 100
    t.string  "ref_exploit",                 :limit => 4096
    t.integer "verify_id"
    t.string  "verify_name",                 :limit => 40
    t.string  "protocol_telnet_flag",        :limit => 3,    :null => false
    t.string  "protocol_http_flag",          :limit => 3,    :null => false
    t.string  "protocol_ftp_flag",           :limit => 3,    :null => false
    t.string  "protocol_dns_flag",           :limit => 3,    :null => false
    t.string  "protocol_finger_flag",        :limit => 3,    :null => false
    t.string  "protocol_sunrpc_flag",        :limit => 3,    :null => false
    t.string  "sarm_cat_name",               :limit => 20
    t.string  "sarm_cat_desc",               :limit => 254
    t.string  "os_name_list",                :limit => 1000
    t.string  "os_variant_name_list",        :limit => 1000
    t.string  "os_distro_name_list",         :limit => 1000
    t.string  "os_distro_version_name_list", :limit => 1000
  end

  add_index "dim_comm_vuln", ["title"], :name => "dim_comm_vuln_x1"

  create_table "dim_comm_vuln_app", :primary_key => "app_row_id", :force => true do |t|
    t.integer   "vuln_id",                     :null => false
    t.string    "app_name",     :limit => 254
    t.timestamp "lu_timestamp"
  end

  add_index "dim_comm_vuln_app", ["vuln_id"], :name => "dim_comm_vuln_app_x1"

  create_table "dim_comm_vuln_os", :primary_key => "os_row_id", :force => true do |t|
    t.integer "vuln_id",                               :null => false
    t.integer "os_id"
    t.string  "os_name",                :limit => 100
    t.integer "os_variant_id"
    t.string  "os_variant_name",        :limit => 80
    t.integer "os_distro_id"
    t.string  "os_distro_name",         :limit => 80
    t.integer "os_distro_version_id"
    t.string  "os_distro_version_name", :limit => 200
  end

  add_index "dim_comm_vuln_os", ["os_id"], :name => "dim_comm_vuln_os_x2"
  add_index "dim_comm_vuln_os", ["os_name"], :name => "dim_comm_vuln_os_x3"
  add_index "dim_comm_vuln_os", ["vuln_id"], :name => "dim_comm_vuln_os_x1"

  create_table "dim_comm_vuln_source", :primary_key => "vuln_map_row_id", :force => true do |t|
    t.integer "vuln_id",                    :null => false
    t.integer "source_id"
    t.string  "source_key",  :limit => 200
    t.string  "source_url",  :limit => 300
    t.string  "comment",     :limit => 200
    t.string  "source_name", :limit => 20
    t.string  "short_desc",  :limit => 20
    t.string  "description"
  end

  add_index "dim_comm_vuln_source", ["source_id"], :name => "dim_comm_vuln_source_x2"
  add_index "dim_comm_vuln_source", ["vuln_id"], :name => "dim_comm_vuln_source_x1"

  create_table "dim_ids_action", :primary_key => "action_id", :force => true do |t|
    t.string "action_name",     :limit => 20,  :null => false
    t.string "action_category", :limit => 20,  :null => false
    t.string "action_desc",     :limit => 254
  end

  create_table "dim_ids_mode", :primary_key => "mode_id", :force => true do |t|
    t.string "mode_name", :limit => 10, :null => false
  end

  create_table "dim_ids_network", :primary_key => "network_id", :force => true do |t|
    t.string "network_name", :limit => 10, :null => false
  end

  create_table "dim_ids_protocol", :primary_key => "protocol_id", :force => true do |t|
    t.string "protocol_name", :limit => 40, :null => false
  end

  create_table "dim_ids_quality", :primary_key => "quality_id", :force => true do |t|
    t.string "device_timestamp", :limit => 1, :null => false
    t.string "device_id",        :limit => 1, :null => false
    t.string "ids_type_id",      :limit => 1, :null => false
    t.string "protocol_id",      :limit => 1, :null => false
    t.string "source_ip_int",    :limit => 1, :null => false
    t.string "dest_ip_int",      :limit => 1, :null => false
    t.string "event_cnt",        :limit => 1, :null => false
    t.string "action_id",        :limit => 1, :null => false
    t.string "severity_id",      :limit => 1, :null => false
    t.string "sig_id",           :limit => 1, :null => false
    t.string "source_geoip_id",  :limit => 1, :null => false
    t.string "dest_geoip_id",    :limit => 1, :null => false
    t.string "source_asset_id",  :limit => 1, :null => false
    t.string "dest_asset_id",    :limit => 1, :null => false
    t.string "everything_else",  :limit => 1, :null => false
  end

  create_table "dim_ids_remed", :primary_key => "rem_id", :force => true do |t|
    t.string "rem_name", :limit => 20, :null => false
  end

  create_table "dim_ids_type", :primary_key => "ids_type_id", :force => true do |t|
    t.string "ids_type_name", :limit => 20, :null => false
  end

  create_table "dim_patch_severity", :primary_key => "severity_id", :force => true do |t|
    t.string "severity_cd",   :limit => 10,  :null => false
    t.string "severity_desc", :limit => 254
  end

  add_index "dim_patch_severity", ["severity_cd"], :name => "sql120109175235500", :unique => true

  create_table "dim_patch_status", :primary_key => "patch_status_id", :force => true do |t|
    t.string "patch_status_name", :limit => 20, :null => false
  end

  add_index "dim_patch_status", ["patch_status_name"], :name => "dim_status_uk1", :unique => true

  create_table "dim_patch_type", :primary_key => "patch_type_id", :force => true do |t|
    t.string "patch_type_name", :limit => 10, :null => false
  end

  add_index "dim_patch_type", ["patch_type_name"], :name => "dim_patch_type_uk1", :unique => true

  create_table "dim_patch_vuln", :primary_key => "vuln_id", :force => true do |t|
    t.string "vuln_advisory_no",    :limit => 60,   :null => false
    t.string "vuln_vendor_cd",      :limit => 254,  :null => false
    t.string "vuln_ms_prod_name",   :limit => 254,  :null => false
    t.string "vuln_ms_bulletin_id", :limit => 60,   :null => false
    t.string "vuln_ms_qno",         :limit => 60,   :null => false
    t.string "vuln_ms_reason",      :limit => 254,  :null => false
    t.string "vuln_cve",            :limit => 60,   :null => false
    t.string "vuln_os_name",        :limit => 1000
    t.string "vuln_name",           :limit => 254,  :null => false
    t.string "vuln_desc",           :limit => 5000
  end

  add_index "dim_patch_vuln", ["vuln_advisory_no", "vuln_vendor_cd", "vuln_ms_prod_name", "vuln_ms_bulletin_id", "vuln_ms_qno", "vuln_ms_reason", "vuln_cve"], :name => "dim_patchvuln_uk1", :unique => true

  create_table "dim_scan_asset_period", :primary_key => "period_month_id", :force => true do |t|
    t.integer   "asset_vid",                                   :null => false
    t.integer   "org_l1_id",                                   :null => false
    t.integer   "org_id",                                      :null => false
    t.integer   "asset_id",                                    :null => false
    t.string    "ip_string_primary",           :limit => 40
    t.string    "ip_int_primary",              :limit => 40
    t.string    "ip_string_list",              :limit => 1000
    t.string    "host_name",                   :limit => 254
    t.integer   "os_id",                                       :null => false
    t.string    "os_type",                     :limit => 20,   :null => false
    t.string    "os_product",                  :limit => 20,   :null => false
    t.string    "os_vendor_name",              :limit => 40,   :null => false
    t.string    "os_name",                     :limit => 40,   :null => false
    t.string    "os_ver",                      :limit => 40,   :null => false
    t.string    "system_status",               :limit => 10,   :null => false
    t.string    "encryption_flag",             :limit => 1,    :null => false
    t.string    "hc_auto_flag",                :limit => 1,    :null => false
    t.integer   "hc_interval_weeks"
    t.string    "hc_manual_flag",              :limit => 1
    t.integer   "hc_manual_interval_weeks"
    t.string    "security_policy_name",        :limit => 40
    t.string    "disaster_recovery_flag",      :limit => 1
    t.string    "internet_accessible_flag",    :limit => 1
    t.string    "vital_business_process_flag", :limit => 1
    t.date      "hc_start_date"
    t.integer   "hc_group_id",                                 :null => false
    t.string    "hc_group_name",               :limit => 80,   :null => false
    t.timestamp "hc_creation_timestamp",                       :null => false
    t.timestamp "lu_timestamp",                                :null => false
  end

  add_index "dim_scan_asset_period", ["asset_id"], :name => "dim_scan_asset_per_x2"
  add_index "dim_scan_asset_period", ["lu_timestamp"], :name => "dim_scan_asset_per_x1"
  add_index "dim_scan_asset_period", ["org_l1_id", "org_id", "host_name"], :name => "dim_scan_asset_per_x3"
  add_index "dim_scan_asset_period", ["org_l1_id", "org_id", "ip_int_primary"], :name => "dim_scan_asset_per_x4"
  add_index "dim_scan_asset_period", ["period_month_id", "asset_id"], :name => "dim_scan_asset_per_uk1", :unique => true

  create_table "dim_scan_org_period", :primary_key => "org_l1_id", :force => true do |t|
    t.integer   "org_id",                               :null => false
    t.integer   "period_month_id",                      :null => false
    t.integer   "year",                                 :null => false
    t.integer   "quarter_id",                           :null => false
    t.integer   "quarter_of_year",                      :null => false
    t.string    "month_name",             :limit => 10, :null => false
    t.integer   "month_of_year",                        :null => false
    t.integer   "month_of_quarter",                     :null => false
    t.integer   "days_in_month",                        :null => false
    t.string    "period_override_flag",   :limit => 1,  :null => false
    t.integer   "hip_period_id",                        :null => false
    t.timestamp "asset_freeze_timestamp",               :null => false
  end

  add_index "dim_scan_org_period", ["org_l1_id", "org_id", "year", "month_of_year"], :name => "dim_scan_org_period_uk1", :unique => true
  add_index "dim_scan_org_period", ["period_month_id", "org_l1_id", "org_id"], :name => "dim_scan_org_period_x1"

  create_table "dim_scan_period", :primary_key => "period_month_id", :force => true do |t|
    t.integer "year",                           :null => false
    t.integer "quarter_id",                     :null => false
    t.integer "quarter_of_year",                :null => false
    t.string  "month_name",       :limit => 10, :null => false
    t.integer "month_of_year",                  :null => false
    t.integer "month_of_quarter",               :null => false
    t.integer "days_in_month",                  :null => false
  end

  create_table "dim_scan_scan_period", :primary_key => "period_month_id", :force => true do |t|
    t.integer   "scan_id",                               :null => false
    t.integer   "org_l1_id",                             :null => false
    t.integer   "org_id",                                :null => false
    t.integer   "asset_vid",                             :null => false
    t.integer   "tool_id",                               :null => false
    t.string    "tool_name",               :limit => 20, :null => false
    t.integer   "scan_date_id",                          :null => false
    t.timestamp "scan_start_timestamp",                  :null => false
    t.timestamp "scan_stop_timestamp",                   :null => false
    t.string    "scan_type",               :limit => 20
    t.timestamp "publish_ready_timestamp"
    t.string    "publish_ready_userid",    :limit => 20
    t.timestamp "publish_timestamp"
    t.integer   "publish_date_id"
    t.timestamp "lu_timestamp",                          :null => false
  end

  add_index "dim_scan_scan_period", ["asset_vid"], :name => "dim_scan_scan_per_x2"
  add_index "dim_scan_scan_period", ["lu_timestamp"], :name => "dim_scan_scan_per_x4"
  add_index "dim_scan_scan_period", ["org_l1_id", "org_id"], :name => "dim_scan_scan_per_x3"
  add_index "dim_scan_scan_period", ["scan_id"], :name => "dim_scan_scan_per_x1"

  create_table "dim_scan_suppress_finding_period", :primary_key => "period_month_id", :force => true do |t|
    t.integer   "suppress_id",  :null => false
    t.integer   "org_l1_id",    :null => false
    t.integer   "org_id",       :null => false
    t.integer   "asset_vid",    :null => false
    t.integer   "finding_id",   :null => false
    t.integer   "finding_vid",  :null => false
    t.timestamp "lu_timestamp", :null => false
  end

  add_index "dim_scan_suppress_finding_period", ["lu_timestamp"], :name => "dim_scan_sgf_x2"
  add_index "dim_scan_suppress_finding_period", ["org_l1_id"], :name => "dim_scan_sgf_x1"

  create_table "dim_scan_suppress_group_period", :primary_key => "period_month_id", :force => true do |t|
    t.integer   "suppress_id",                 :null => false
    t.integer   "org_l1_id",                   :null => false
    t.integer   "org_id",                      :null => false
    t.integer   "hc_group_id",                 :null => false
    t.string    "hc_group_name", :limit => 80, :null => false
    t.timestamp "lu_timestamp",                :null => false
  end

  add_index "dim_scan_suppress_group_period", ["lu_timestamp"], :name => "dim_scan_sgp_x2"
  add_index "dim_scan_suppress_group_period", ["org_l1_id"], :name => "dim_scan_sgp_x1"

  create_table "dim_scan_suppress_period", :primary_key => "period_month_id", :force => true do |t|
    t.integer   "suppress_id",                             :null => false
    t.integer   "org_l1_id",                               :null => false
    t.integer   "org_id",                                  :null => false
    t.string    "suppress_name",            :limit => 100, :null => false
    t.string    "suppress_desc",            :limit => 500
    t.timestamp "suppress_start_timestamp",                :null => false
    t.integer   "suppress_start_date_id",                  :null => false
    t.timestamp "suppress_stop_timestamp",                 :null => false
    t.integer   "suppress_stop_date_id",                   :null => false
    t.string    "suppress_class",           :limit => 25,  :null => false
    t.string    "suppress_status",          :limit => 15
    t.string    "suppress_auto_flag",       :limit => 1,   :null => false
    t.string    "suppress_scope",           :limit => 40,  :null => false
    t.integer   "vuln_id"
    t.integer   "asset_vid"
    t.integer   "asset_id"
    t.timestamp "lu_timestamp",                            :null => false
  end

  add_index "dim_scan_suppress_period", ["lu_timestamp"], :name => "dim_scan_suppress_per_x2"
  add_index "dim_scan_suppress_period", ["suppress_stop_date_id"], :name => "dim_scan_suppress_per_x1"

  create_table "fact_ids", :id => false, :force => true do |t|
    t.integer   "row_id",           :limit => 19, :null => false
    t.string    "sem_event_cd",     :limit => 20
    t.integer   "device_date_id",                 :null => false
    t.timestamp "device_timestamp",               :null => false
    t.integer   "sem_date_id",                    :null => false
    t.timestamp "sem_timestamp",                  :null => false
    t.integer   "device_id",                      :null => false
    t.integer   "ids_type_id",                    :null => false
    t.integer   "protocol_id",                    :null => false
    t.integer   "source_ip_int1",   :limit => 19
    t.integer   "source_ip_int2",   :limit => 19
    t.integer   "source_port"
    t.integer   "source_geoip_id",                :null => false
    t.integer   "source_asset_id",                :null => false
    t.integer   "dest_ip_int1",     :limit => 19
    t.integer   "dest_ip_int2",     :limit => 19
    t.integer   "dest_port"
    t.integer   "dest_geoip_id",                  :null => false
    t.integer   "dest_asset_id",                  :null => false
    t.integer   "sig_id",                         :null => false
    t.integer   "severity_id",                    :null => false
    t.integer   "action_id",                      :null => false
    t.integer   "event_cnt",                      :null => false
    t.integer   "batch_id",                       :null => false
    t.integer   "quality_id",                     :null => false
  end

  add_index "fact_ids", ["device_id"], :name => "fact_ids_x1"
  add_index "fact_ids", ["sig_id"], :name => "fact_ids_x2"

  create_table "fact_ids_detach", :id => false, :force => true do |t|
    t.integer   "row_id",           :limit => 19, :null => false
    t.string    "sem_event_cd",     :limit => 20
    t.integer   "device_date_id",                 :null => false
    t.timestamp "device_timestamp",               :null => false
    t.integer   "sem_date_id",                    :null => false
    t.timestamp "sem_timestamp",                  :null => false
    t.integer   "device_id",                      :null => false
    t.integer   "ids_type_id",                    :null => false
    t.integer   "protocol_id",                    :null => false
    t.integer   "source_ip_int1",   :limit => 19
    t.integer   "source_ip_int2",   :limit => 19
    t.integer   "source_port"
    t.integer   "source_geoip_id",                :null => false
    t.integer   "source_asset_id",                :null => false
    t.integer   "dest_ip_int1",     :limit => 19
    t.integer   "dest_ip_int2",     :limit => 19
    t.integer   "dest_port"
    t.integer   "dest_geoip_id",                  :null => false
    t.integer   "dest_asset_id",                  :null => false
    t.integer   "sig_id",                         :null => false
    t.integer   "severity_id",                    :null => false
    t.integer   "action_id",                      :null => false
    t.integer   "event_cnt",                      :null => false
    t.integer   "batch_id",                       :null => false
    t.integer   "quality_id",                     :null => false
  end

  add_index "fact_ids_detach", ["device_id"], :name => "sql101101002720300"
  add_index "fact_ids_detach", ["ids_type_id"], :name => "sql120109175254700"
  add_index "fact_ids_detach", ["sig_id"], :name => "sql101101002720310"

  create_table "fact_patch", :primary_key => "tool_asset_id", :force => true do |t|
    t.integer   "vuln_id",                           :null => false
    t.timestamp "row_from_timestamp",                :null => false
    t.timestamp "row_to_timestamp"
    t.string    "delete_flag",        :limit => 1,   :null => false
    t.integer   "org_l1_id",                         :null => false
    t.integer   "org_id",                            :null => false
    t.integer   "source_tool_id",                    :null => false
    t.integer   "patch_type_id",                     :null => false
    t.integer   "cods_asset_id",                     :null => false
    t.integer   "status_id",                         :null => false
    t.integer   "severity_id",                       :null => false
    t.integer   "discovered_date_id",                :null => false
    t.integer   "due_date_id",                       :null => false
    t.integer   "installed_date_id",                 :null => false
    t.string    "comments",           :limit => 254
    t.timestamp "lu_timestamp"
  end

  add_index "fact_patch", ["cods_asset_id"], :name => "fact_patch_x4"
  add_index "fact_patch", ["org_id"], :name => "fact_patch_x1"
  add_index "fact_patch", ["org_l1_id", "status_id", "severity_id"], :name => "sql120109175235930"
  add_index "fact_patch", ["org_l1_id"], :name => "sql120109175236070"
  add_index "fact_patch", ["severity_id"], :name => "sql120109175235960"
  add_index "fact_patch", ["status_id"], :name => "sql120109175236050"
  add_index "fact_patch", ["tool_asset_id"], :name => "fact_patch_x2"
  add_index "fact_patch", ["vuln_id"], :name => "fact_patch_x3"

  create_table "fact_scan", :primary_key => "finding_vid", :force => true do |t|
    t.integer   "finding_id",                                       :null => false
    t.timestamp "row_from_timestamp",                               :null => false
    t.integer   "row_from_date_id",                                 :null => false
    t.timestamp "row_to_timestamp"
    t.integer   "row_to_date_id"
    t.integer   "row_to_date_id_gen"
    t.timestamp "scan_timestamp",                                   :null => false
    t.integer   "asset_id",                                         :null => false
    t.integer   "org_id",                                           :null => false
    t.integer   "org_l1_id",                                        :null => false
    t.integer   "org_l1_id_gen",                                    :null => false
    t.string    "scan_service",       :limit => 10,                 :null => false
    t.integer   "scan_tool_id",                                     :null => false
    t.integer   "vuln_id",                                          :null => false
    t.integer   "severity_id",                                      :null => false
    t.integer   "port",                                             :null => false
    t.integer   "protocol_id",                                      :null => false
    t.string    "cat_name",           :limit => 20
    t.integer   "quality_id",                        :default => 0, :null => false
    t.timestamp "lu_timestamp",                                     :null => false
    t.string    "finding_hash",       :limit => 16,                 :null => false
    t.string    "finding_text",       :limit => 700,                :null => false
  end

  add_index "fact_scan", ["asset_id", "finding_hash", "port", "protocol_id", "row_from_timestamp"], :name => "fact_scan_uk2", :unique => true
  add_index "fact_scan", ["asset_id", "finding_id"], :name => "fact_scan_x3"
  add_index "fact_scan", ["finding_id", "row_from_timestamp"], :name => "fact_scan_uk1", :unique => true
  add_index "fact_scan", ["lu_timestamp"], :name => "fact_scan_x4"
  add_index "fact_scan", ["org_l1_id_gen", "row_to_date_id_gen", "severity_id"], :name => "sql120109175246340"
  add_index "fact_scan", ["org_l1_id_gen"], :name => "sql120109175246440"
  add_index "fact_scan", ["row_from_date_id"], :name => "fact_scan_x2"
  add_index "fact_scan", ["row_to_date_id_gen"], :name => "sql120109175246420"
  add_index "fact_scan", ["severity_id"], :name => "sql120109175246380"
  add_index "fact_scan", ["vuln_id"], :name => "fact_scan_x1"

  create_table "fact_scan_bkup", :id => false, :force => true do |t|
    t.integer   "finding_vid",                                      :null => false
    t.integer   "finding_id",                                       :null => false
    t.timestamp "row_from_timestamp",                               :null => false
    t.integer   "row_from_date_id",                                 :null => false
    t.timestamp "row_to_timestamp"
    t.integer   "row_to_date_id"
    t.integer   "row_to_date_id_gen"
    t.timestamp "scan_timestamp",                                   :null => false
    t.integer   "asset_id",                                         :null => false
    t.integer   "org_id",                                           :null => false
    t.integer   "org_l1_id",                                        :null => false
    t.integer   "org_l1_id_gen",                                    :null => false
    t.string    "scan_service",       :limit => 10,                 :null => false
    t.integer   "scan_tool_id",                                     :null => false
    t.integer   "vuln_id",                                          :null => false
    t.integer   "severity_id",                                      :null => false
    t.integer   "port",                                             :null => false
    t.integer   "protocol_id",                                      :null => false
    t.timestamp "lu_timestamp",                                     :null => false
    t.integer   "quality_id",                        :default => 0, :null => false
    t.string    "finding_hash",       :limit => 16,                 :null => false
    t.string    "finding_text",       :limit => 700,                :null => false
  end

  create_table "facts_ids_dev_daily_nonmqt", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "device_id",      :null => false
    t.integer "event_cnt",      :null => false
    t.integer "batch_id",       :null => false
  end

  add_index "facts_ids_dev_daily_nonmqt", ["device_date_id"], :name => "sql120109175247020"
  add_index "facts_ids_dev_daily_nonmqt", ["device_id"], :name => "facts_ids_dd_x2"

  create_table "facts_ids_dev_score_daily", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "device_id",      :null => false
    t.integer "score_id",       :null => false
    t.integer "value",          :null => false
    t.integer "batch_id",       :null => false
  end

  add_index "facts_ids_dev_score_daily", ["device_date_id", "value"], :name => "facts_ids_dsd_x3"
  add_index "facts_ids_dev_score_daily", ["device_date_id"], :name => "sql120109175247450"
  add_index "facts_ids_dev_score_daily", ["device_id"], :name => "facts_ids_dsd_x1"
  add_index "facts_ids_dev_score_daily", ["score_id"], :name => "facts_ids_dsd_x2"

  create_table "facts_ids_dev_sev_sig_type_daily_nonmqt", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "device_id",      :null => false
    t.integer "severity_id",    :null => false
    t.integer "sig_id",         :null => false
    t.integer "ids_type_id",    :null => false
    t.integer "event_cnt",      :null => false
    t.integer "batch_id",       :null => false
  end

  add_index "facts_ids_dev_sev_sig_type_daily_nonmqt", ["device_date_id"], :name => "sql120109175244170"
  add_index "facts_ids_dev_sev_sig_type_daily_nonmqt", ["device_id"], :name => "facts_ids_dsstdn_x2"
  add_index "facts_ids_dev_sev_sig_type_daily_nonmqt", ["sig_id"], :name => "facts_ids_dsstdn_x3"

  create_table "facts_ids_sig_emerging_daily_nonmqt", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "sig_id",         :null => false
    t.integer "event_cnt",      :null => false
    t.integer "change_score",   :null => false
    t.integer "batch_id",       :null => false
  end

  add_index "facts_ids_sig_emerging_daily_nonmqt", ["device_date_id"], :name => "sql120109175247200"
  add_index "facts_ids_sig_emerging_daily_nonmqt", ["sig_id"], :name => "facts_ids_sed_x1"

  create_table "facts_ids_sig_score_daily", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "sig_id",         :null => false
    t.integer "score_id",       :null => false
    t.integer "value",          :null => false
    t.integer "batch_id",       :null => false
  end

  add_index "facts_ids_sig_score_daily", ["device_date_id"], :name => "sql120109175247650"
  add_index "facts_ids_sig_score_daily", ["score_id"], :name => "facts_ids_ssd_x2"
  add_index "facts_ids_sig_score_daily", ["sig_id"], :name => "facts_ids_ssd_x1"

  create_table "facts_ids_sig_type_daily_nonmqt", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "sig_id",         :null => false
    t.integer "ids_type_id",    :null => false
    t.integer "event_cnt",      :null => false
    t.integer "batch_id",       :null => false
  end

  add_index "facts_ids_sig_type_daily_nonmqt", ["device_date_id"], :name => "sql120109175244410"
  add_index "facts_ids_sig_type_daily_nonmqt", ["ids_type_id"], :name => "facts_ids_stdn_x2"
  add_index "facts_ids_sig_type_daily_nonmqt", ["sig_id"], :name => "facts_ids_stdn_x1"

  create_table "facts_scan_asset_misc_period", :id => false, :force => true do |t|
    t.integer   "period_month_id",               :null => false
    t.integer   "org_id",                        :null => false
    t.integer   "org_l1_id",                     :null => false
    t.integer   "org_l1_id_gen",                 :null => false
    t.integer   "asset_vid",                     :null => false
    t.string    "validate_flag",   :limit => 1,  :null => false
    t.string    "suppress_flag",   :limit => 1,  :null => false
    t.string    "publish_flag",    :limit => 1,  :null => false
    t.integer   "severity_id",                   :null => false
    t.string    "cat_name",        :limit => 20, :null => false
    t.integer   "finding_cnt",                   :null => false
    t.timestamp "lu_timestamp",                  :null => false
  end

  add_index "facts_scan_asset_misc_period", ["org_l1_id_gen"], :name => "sql120109175250910"
  add_index "facts_scan_asset_misc_period", ["period_month_id", "org_l1_id", "org_id", "asset_vid"], :name => "facts_scan_am_period_x1"
  add_index "facts_scan_asset_misc_period", ["period_month_id", "org_l1_id_gen"], :name => "sql120109175250890"
  add_index "facts_scan_asset_misc_period", ["period_month_id"], :name => "sql120109175250930"

  create_table "facts_scan_asset_supp_period", :id => false, :force => true do |t|
    t.integer   "period_month_id", :null => false
    t.integer   "org_l1_id",       :null => false
    t.integer   "org_id",          :null => false
    t.integer   "org_l1_id_gen",   :null => false
    t.integer   "asset_vid",       :null => false
    t.integer   "suppress_id",     :null => false
    t.integer   "finding_cnt",     :null => false
    t.timestamp "lu_timestamp",    :null => false
  end

  add_index "facts_scan_asset_supp_period", ["org_l1_id_gen"], :name => "sql120109175251320"
  add_index "facts_scan_asset_supp_period", ["period_month_id", "org_l1_id", "org_id", "asset_vid"], :name => "facts_scan_asset_supp_period_x1"
  add_index "facts_scan_asset_supp_period", ["period_month_id", "org_l1_id_gen"], :name => "sql120109175251290"
  add_index "facts_scan_asset_supp_period", ["period_month_id"], :name => "sql120109175251330"

  create_table "facts_scan_asset_vuln_misc_period", :id => false, :force => true do |t|
    t.integer   "period_month_id",               :null => false
    t.integer   "org_l1_id",                     :null => false
    t.integer   "org_id",                        :null => false
    t.integer   "asset_vid",                     :null => false
    t.integer   "scan_id",                       :null => false
    t.integer   "tool_id",                       :null => false
    t.integer   "vuln_id",                       :null => false
    t.string    "validate_flag",   :limit => 1,  :null => false
    t.string    "suppress_flag",   :limit => 1,  :null => false
    t.string    "publish_flag",    :limit => 1,  :null => false
    t.integer   "severity_id",                   :null => false
    t.string    "cat_name",        :limit => 20, :null => false
    t.integer   "finding_cnt",                   :null => false
    t.timestamp "lu_timestamp",                  :null => false
  end

  add_index "facts_scan_asset_vuln_misc_period", ["org_l1_id"], :name => "sql120109175251110"
  add_index "facts_scan_asset_vuln_misc_period", ["period_month_id", "org_l1_id", "org_id", "asset_vid"], :name => "facts_scan_avm_period_x1"
  add_index "facts_scan_asset_vuln_misc_period", ["period_month_id", "org_l1_id"], :name => "sql120109175251080"
  add_index "facts_scan_asset_vuln_misc_period", ["period_month_id"], :name => "sql120109175251120"
  add_index "facts_scan_asset_vuln_misc_period", ["vuln_id"], :name => "facts_scan_avm_period_x2"

  create_table "facts_scan_org_vuln_period", :primary_key => "period_month_id", :force => true do |t|
    t.integer   "org_l1_id",    :null => false
    t.integer   "org_id",       :null => false
    t.integer   "vuln_id",      :null => false
    t.integer   "finding_cnt",  :null => false
    t.integer   "system_cnt",   :null => false
    t.timestamp "lu_timestamp", :null => false
  end

  add_index "facts_scan_org_vuln_period", ["org_l1_id", "org_id"], :name => "facts_scan_org_vuln_period_x1"
  add_index "facts_scan_org_vuln_period", ["period_month_id"], :name => "sql120109175251470"
  add_index "facts_scan_org_vuln_period", ["vuln_id"], :name => "facts_scan_org_vuln_period_x2"

  create_table "facts_scan_period", :primary_key => "period_month_id", :force => true do |t|
    t.integer   "finding_vid",                      :null => false
    t.integer   "org_l1_id",                        :null => false
    t.integer   "org_id",                           :null => false
    t.integer   "org_l1_id_gen",                    :null => false
    t.integer   "asset_vid",                        :null => false
    t.integer   "tool_id",                          :null => false
    t.integer   "scan_id",                          :null => false
    t.integer   "vuln_id",                          :null => false
    t.string    "validate_flag",     :limit => 1,   :null => false
    t.string    "suppress_flag",     :limit => 1,   :null => false
    t.integer   "suppress_id"
    t.integer   "suppress_cnt",                     :null => false
    t.string    "release_flag",      :limit => 1,   :null => false
    t.string    "auto_release_flag", :limit => 1,   :null => false
    t.integer   "release_date_id",                  :null => false
    t.string    "publish_flag",      :limit => 1,   :null => false
    t.integer   "publish_date_id",                  :null => false
    t.integer   "port",                             :null => false
    t.integer   "severity_id",                      :null => false
    t.integer   "finding_id",                       :null => false
    t.integer   "protocol_id",                      :null => false
    t.string    "cat_name",          :limit => 20,  :null => false
    t.timestamp "lu_timestamp",                     :null => false
    t.string    "result",            :limit => 10
    t.string    "finding_text",      :limit => 700
  end

  add_index "facts_scan_period", ["period_month_id", "org_l1_id", "org_id", "asset_vid"], :name => "facts_scan_period_x1"
  add_index "facts_scan_period", ["vuln_id"], :name => "facts_scan_period_x2"

  create_table "facts_scan_vuln_score_daily", :id => false, :force => true do |t|
    t.integer "scan_date_id", :null => false
    t.integer "vuln_id",      :null => false
    t.integer "score_id",     :null => false
    t.integer "value",        :null => false
    t.integer "batch_id",     :null => false
  end

  add_index "facts_scan_vuln_score_daily", ["scan_date_id", "value"], :name => "facts_scan_vsd_x3"
  add_index "facts_scan_vuln_score_daily", ["scan_date_id"], :name => "sql120109175250220"
  add_index "facts_scan_vuln_score_daily", ["score_id"], :name => "facts_scan_vsd_x2"
  add_index "facts_scan_vuln_score_daily", ["vuln_id"], :name => "facts_scan_vsd_x1"

  create_table "misc_comm_auth", :primary_key => "auth_id", :force => true do |t|
    t.string    "user_name",             :limit => 80,                     :null => false
    t.string    "user_desc",             :limit => 80,                     :null => false
    t.string    "user_role",             :limit => 80,                     :null => false
    t.string    "user_org",              :limit => 80,                     :null => false
    t.string    "user_type",             :limit => 10,                     :null => false
    t.string    "application_name",      :limit => 40,                     :null => false
    t.string    "subject_area",          :limit => 20
    t.integer   "org_l1_id"
    t.integer   "org_id"
    t.string    "metric_type_security",  :limit => 5,  :default => "none", :null => false
    t.string    "metric_type_process",   :limit => 5,  :default => "none", :null => false
    t.string    "metric_type_financial", :limit => 5,  :default => "none", :null => false
    t.string    "status",                :limit => 10, :default => "open", :null => false
    t.date      "revalidation_date"
    t.string    "revalidation_user",     :limit => 20
    t.string    "lu_userid",             :limit => 20,                     :null => false
    t.timestamp "lu_timestamp",                                            :null => false
  end

  create_table "misc_scan_finding_audit", :primary_key => "asset_id", :force => true do |t|
    t.integer   "batch_id",                      :null => false
    t.integer   "finding_vid",                   :null => false
    t.integer   "publish_date_id",               :null => false
    t.integer   "finding_id",                    :null => false
    t.timestamp "scan_timestamp",                :null => false
    t.integer   "org_id",                        :null => false
    t.integer   "org_l1_id",                     :null => false
    t.integer   "org_l1_id_gen",                 :null => false
    t.integer   "vuln_id",                       :null => false
    t.integer   "scan_id",                       :null => false
    t.string    "validate_flag",    :limit => 1
    t.string    "suppress_flag",    :limit => 1
    t.string    "consolidate_flag", :limit => 1
    t.string    "publish_flag",     :limit => 1
    t.integer   "suppress_id"
    t.integer   "port",                          :null => false
    t.integer   "severity_id",                   :null => false
    t.integer   "protocol_id",                   :null => false
    t.integer   "scan_tool_id",                  :null => false
    t.timestamp "lu_timestamp",                  :null => false
  end

  create_table "misc_scan_reject", :primary_key => "org_l1_id", :force => true do |t|
    t.integer   "org_id",                                :null => false
    t.integer   "org_l1_id_gen",                         :null => false
    t.string    "host_name",              :limit => 100
    t.string    "host_ip_string",         :limit => 40
    t.string    "host_id_gen",            :limit => 100, :null => false
    t.integer   "scan_tool_id",                          :null => false
    t.integer   "scan_id",                               :null => false
    t.timestamp "scan_start_timestamp",                  :null => false
    t.integer   "scan_start_date_id",                    :null => false
    t.integer   "scan_start_date_id_gen",                :null => false
    t.string    "os_name",                :limit => 100, :null => false
    t.integer   "num_findings",                          :null => false
    t.string    "reject_reason",          :limit => 254, :null => false
    t.string    "filename",               :limit => 254, :null => false
    t.string    "sub_filename",           :limit => 254
    t.timestamp "reject_timestamp",                      :null => false
    t.string    "reject_program",         :limit => 100, :null => false
    t.integer   "extract_batch_id",                      :null => false
    t.integer   "transform_batch_id",                    :null => false
    t.integer   "load_batch_id",                         :null => false
    t.timestamp "lu_timestamp",                          :null => false
  end

  add_index "misc_scan_reject", ["host_ip_string"], :name => "misc_scan_reject_x1"
  add_index "misc_scan_reject", ["host_name"], :name => "misc_scan_reject_x2"
  add_index "misc_scan_reject", ["org_l1_id_gen", "scan_start_date_id_gen"], :name => "sql120109175245570"
  add_index "misc_scan_reject", ["org_l1_id_gen"], :name => "sql120109175245610"
  add_index "misc_scan_reject", ["scan_start_date_id_gen"], :name => "sql120109175245600"

  create_table "staging_dim_comm_org_mss", :primary_key => "source_cust_id", :force => true do |t|
    t.decimal "source_cust_mrr",                         :precision => 10, :scale => 2
    t.string  "source_cust_status",       :limit => 20
    t.string  "source_cust_name",         :limit => 80
    t.string  "source_partner_id",        :limit => 20
    t.string  "source_partner_name",      :limit => 80
    t.string  "source_customer_category", :limit => 60
    t.string  "source_industry",          :limit => 120
    t.string  "source_regulated",         :limit => 10
    t.string  "source_mids",              :limit => 10
    t.integer "source_num_ids"
    t.string  "source_mps",               :limit => 10
    t.string  "source_mfs",               :limit => 10
    t.integer "source_num_fw"
    t.string  "source_selm",              :limit => 10
    t.string  "source_vms",               :limit => 10
    t.integer "source_num_ext_ip"
    t.integer "source_num_int_ip"
    t.integer "source_num_scanners"
    t.string  "source_lms",               :limit => 10
    t.string  "source_eam",               :limit => 10
    t.integer "source_num_devices"
    t.string  "source_third_party",       :limit => 10
    t.string  "source_service_name",      :limit => 60
    t.string  "source_sia",               :limit => 10
    t.string  "source_sia_name",          :limit => 60
    t.string  "source_pci_dss",           :limit => 10
    t.string  "source_hipaa",             :limit => 10
    t.string  "source_glba",              :limit => 10
    t.integer "industry_id",                                                            :default => 0,     :null => false
    t.string  "ind_section_cd",           :limit => 1,                                  :default => "0",   :null => false
    t.string  "ind_section_name",         :limit => 200,                                :default => "unk", :null => false
    t.string  "ind_section_short_name",   :limit => 40,                                 :default => "unk", :null => false
    t.integer "ind_division_cd",                                                        :default => 0,     :null => false
    t.string  "ind_division_name",        :limit => 200,                                :default => "unk", :null => false
    t.string  "ind_division_short_name",  :limit => 40,                                 :default => "unk", :null => false
    t.string  "cons_db_ip_string",        :limit => 20
    t.string  "cons_db_hostname",         :limit => 80
    t.string  "fw_db_ip_string",          :limit => 20
    t.string  "fw_db_hostname",           :limit => 80
    t.string  "lms_agg_ip_string",        :limit => 20
    t.string  "lms_agg_hostname",         :limit => 80
  end

  create_table "staging_dim_comm_tool_asset_mss", :primary_key => "source_device_id", :force => true do |t|
    t.string "source_cust_device_name",       :limit => 120
    t.string "source_machine_host_name",      :limit => 120
    t.string "source_machine_platform",       :limit => 40
    t.string "source_cust_id",                :limit => 20
    t.string "source_status",                 :limit => 60
    t.string "source_service_name",           :limit => 60
    t.string "source_manufacturer",           :limit => 60
    t.string "source_software_version",       :limit => 60
    t.string "source_sensor_type",            :limit => 40
    t.string "source_primary_function",       :limit => 100
    t.string "source_primary_application",    :limit => 80
    t.string "source_ids_config_type",        :limit => 40
    t.string "source_network_seg_type",       :limit => 40
    t.string "source_inline_appliance_mode",  :limit => 40
    t.string "source_stacked_flag",           :limit => 3
    t.string "source_managed_by",             :limit => 40
    t.string "source_monitored_by",           :limit => 15
    t.string "source_cluster_fw_name",        :limit => 60
    t.string "source_ids_config_type2",       :limit => 60
    t.string "source_fw_type_and_ver",        :limit => 60
    t.string "source_default_gateway",        :limit => 120
    t.string "source_ip_ext_string",          :limit => 60
    t.string "source_os_name",                :limit => 60
    t.string "source_nlr_threshold",          :limit => 60
    t.string "source_poll_period",            :limit => 40
    t.string "source_site_name",              :limit => 120
    t.string "source_site_id",                :limit => 40
    t.string "source_data_retention_period",  :limit => 40
    t.string "source_index_retention_period", :limit => 40
    t.string "source_timezone",               :limit => 60
  end

  create_table "staging_ids_dev_sev_sig_type_daily", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "device_id",      :null => false
    t.integer "severity_id",    :null => false
    t.integer "sig_id",         :null => false
    t.integer "ids_type_id",    :null => false
    t.integer "event_cnt"
    t.integer "batch_id"
  end

  add_index "staging_ids_dev_sev_sig_type_daily", ["batch_id"], :name => "sql120109175239830"

  create_table "staging_ids_sig_type_daily", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "sig_id",         :null => false
    t.integer "ids_type_id",    :null => false
    t.integer "event_cnt"
    t.integer "batch_id"
  end

  add_index "staging_ids_sig_type_daily", ["batch_id"], :name => "sql120109175239680"

  create_table "staging_scan_finding", :primary_key => "finding_id", :force => true do |t|
    t.integer "org_l1_id",                                      :null => false
    t.integer "asset_id",                                       :null => false
    t.string  "host_ip_int",  :limit => 100, :default => "0",   :null => false
    t.string  "host_name",    :limit => 200, :default => "unk", :null => false
    t.integer "scan_tool_id",                                   :null => false
    t.string  "finding_text", :limit => 100, :default => "unk", :null => false
  end

  add_index "staging_scan_finding", ["org_l1_id", "asset_id", "host_ip_int", "host_name", "scan_tool_id", "finding_text"], :name => "staging_scanfind_uk1", :unique => true
  add_index "staging_scan_finding", ["org_l1_id"], :name => "sql120109175241580"

  create_table "staging_scan_org_period", :primary_key => "org_l1_id", :force => true do |t|
    t.integer   "org_id",                 :null => false
    t.integer   "period_month_id",        :null => false
    t.integer   "hip_period_id",          :null => false
    t.timestamp "asset_freeze_timestamp", :null => false
  end

  create_table "z_dim_comm_tool_asset", :id => false, :force => true do |t|
    t.integer   "tool_asset_id",                                               :null => false
    t.integer   "org_l1_id",                                                   :null => false
    t.integer   "manager_id"
    t.string    "source_asset_id",           :limit => 40,                     :null => false
    t.string    "ip_string",                 :limit => 20
    t.integer   "ip_int",                    :limit => 19
    t.string    "host_name",                 :limit => 80
    t.string    "os_source_text",            :limit => 40,                     :null => false
    t.string    "tool",                      :limit => 20, :default => "itim"
    t.integer   "org_id",                                  :default => 0
    t.integer   "os_id",                                   :default => 0
    t.timestamp "last_tool_login_timestamp"
    t.timestamp "lu_timestamp"
    t.string    "lu_userid",                 :limit => 20, :default => "unk"
  end

  create_table "z_dim_comm_tool_asset_conn", :id => false, :force => true do |t|
    t.integer   "org_l1_id",                   :null => false
    t.integer   "org_id",                      :null => false
    t.integer   "tool_asset_id",               :null => false
    t.integer   "network_id"
    t.string    "ip_string",     :limit => 15, :null => false
    t.integer   "ip_int",        :limit => 19, :null => false
    t.string    "mac_address",   :limit => 20
    t.string    "host_name",     :limit => 80
    t.string    "lu_userid",     :limit => 20, :null => false
    t.timestamp "lu_timestamp",                :null => false
  end

  create_table "z_dim_comm_tool_asset_scan", :id => false, :force => true do |t|
    t.integer   "org_l1_id",                          :null => false
    t.integer   "org_id",                             :null => false
    t.integer   "tool_asset_id",                      :null => false
    t.integer   "tool_id",                            :null => false
    t.integer   "scan_date_id",                       :null => false
    t.timestamp "scan_start_timestamp",               :null => false
    t.timestamp "scan_stop_timestamp",                :null => false
    t.string    "scan_service",         :limit => 40, :null => false
    t.integer   "extract_batch_id",     :limit => 19
    t.integer   "transform_batch_id",   :limit => 19
    t.integer   "load_batch_id",        :limit => 19
    t.string    "source_scan_id",       :limit => 40
    t.timestamp "lu_timestamp"
  end

  create_table "z_facts_ids_sig_type_daily", :id => false, :force => true do |t|
    t.integer "device_date_id", :null => false
    t.integer "sig_id",         :null => false
    t.integer "ids_type_id",    :null => false
    t.integer "event_cnt"
    t.integer "batch_id"
  end

  create_table "z_staging_dim_comm_org_mss", :id => false, :force => true do |t|
    t.string  "source_cust_id",           :limit => 20
    t.string  "source_cust_name",         :limit => 80
    t.string  "source_partner_id",        :limit => 20
    t.string  "source_partner_name",      :limit => 80
    t.string  "source_customer_category", :limit => 60
    t.string  "source_industry",          :limit => 120
    t.string  "source_regulated",         :limit => 10
    t.string  "source_mids",              :limit => 10
    t.integer "source_num_ids"
    t.string  "source_mps",               :limit => 10
    t.string  "source_mfs",               :limit => 10
    t.integer "source_num_fw"
    t.string  "source_selm",              :limit => 10
    t.string  "source_vms",               :limit => 10
    t.integer "source_num_ext_ip"
    t.integer "source_num_int_ip"
    t.integer "source_num_scanned"
    t.string  "source_lms",               :limit => 10
    t.string  "source_eam",               :limit => 10
    t.integer "source_num_devices"
    t.string  "source_third_party",       :limit => 10
    t.string  "source_service_name",      :limit => 60
    t.string  "source_sia",               :limit => 10
    t.string  "source_sia_name",          :limit => 60
    t.string  "source_pci_dss",           :limit => 10
    t.string  "source_hipaa",             :limit => 10
    t.string  "source_glba",              :limit => 10
  end

  create_table "z_staging_dim_comm_tool_asset_mss", :id => false, :force => true do |t|
    t.string "source_device_id",              :limit => 40
    t.string "source_cust_device_name",       :limit => 120
    t.string "source_machine_host_name",      :limit => 120
    t.string "source_machine_platform",       :limit => 40
    t.string "source_cust_id",                :limit => 20
    t.string "source_status",                 :limit => 60
    t.string "source_service_name",           :limit => 60
    t.string "source_manufacturer",           :limit => 60
    t.string "source_software_version",       :limit => 60
    t.string "source_sensor_type",            :limit => 40
    t.string "source_primary_function",       :limit => 80
    t.string "source_primary_application",    :limit => 80
    t.string "source_ids_config_type",        :limit => 40
    t.string "source_network_seg_type",       :limit => 40
    t.string "source_inline_appliance_mode",  :limit => 40
    t.string "source_stacked_flag",           :limit => 3
    t.string "source_managed_by",             :limit => 40
    t.string "source_monitored_by",           :limit => 15
    t.string "source_cluster_fw_name",        :limit => 60
    t.string "source_ids_config_type2",       :limit => 60
    t.string "source_fw_type_and_ver",        :limit => 60
    t.string "source_default_gateway",        :limit => 120
    t.string "source_ip_ext_string",          :limit => 20
    t.string "source_os_name",                :limit => 60
    t.string "source_nlr_threshold",          :limit => 60
    t.string "source_poll_period",            :limit => 40
    t.string "source_site_name",              :limit => 120
    t.string "source_site_id",                :limit => 40
    t.string "source_data_retention_period",  :limit => 40
    t.string "source_index_retention_period", :limit => 40
    t.string "source_timezone",               :limit => 60
  end

  create_table "zz_staging_dim_comm_tool_asset_mss", :primary_key => "source_device_id", :force => true do |t|
    t.string "source_cust_device_name",       :limit => 120
    t.string "source_machine_host_name",      :limit => 120
    t.string "source_machine_platform",       :limit => 40
    t.string "source_cust_id",                :limit => 20
    t.string "source_status",                 :limit => 60
    t.string "source_service_name",           :limit => 60
    t.string "source_manufacturer",           :limit => 60
    t.string "source_software_version",       :limit => 60
    t.string "source_sensor_type",            :limit => 40
    t.string "source_primary_function",       :limit => 80
    t.string "source_primary_application",    :limit => 80
    t.string "source_ids_config_type",        :limit => 40
    t.string "source_network_seg_type",       :limit => 40
    t.string "source_inline_appliance_mode",  :limit => 40
    t.string "source_stacked_flag",           :limit => 3
    t.string "source_managed_by",             :limit => 40
    t.string "source_monitored_by",           :limit => 15
    t.string "source_cluster_fw_name",        :limit => 60
    t.string "source_ids_config_type2",       :limit => 60
    t.string "source_fw_type_and_ver",        :limit => 60
    t.string "source_default_gateway",        :limit => 120
    t.string "source_ip_ext_string",          :limit => 20
    t.string "source_os_name",                :limit => 60
    t.string "source_nlr_threshold",          :limit => 60
    t.string "source_poll_period",            :limit => 40
    t.string "source_site_name",              :limit => 120
    t.string "source_site_id",                :limit => 40
    t.string "source_data_retention_period",  :limit => 40
    t.string "source_index_retention_period", :limit => 40
    t.string "source_timezone",               :limit => 60
  end

  create_table "zz_staging_dim_comm_tool_org_mss", :primary_key => "source_cust_id", :force => true do |t|
    t.decimal "source_cust_mrr",                         :precision => 10, :scale => 2
    t.string  "source_cust_status",       :limit => 20
    t.string  "source_cust_name",         :limit => 80
    t.string  "source_partner_id",        :limit => 20
    t.string  "source_partner_name",      :limit => 80
    t.string  "source_customer_category", :limit => 60
    t.string  "source_industry",          :limit => 120
    t.string  "source_regulated",         :limit => 10
    t.string  "source_mids",              :limit => 10
    t.integer "source_num_ids"
    t.string  "source_mps",               :limit => 10
    t.string  "source_mfs",               :limit => 10
    t.integer "source_num_fw"
    t.string  "source_selm",              :limit => 10
    t.string  "source_vms",               :limit => 10
    t.integer "source_num_ext_ip"
    t.integer "source_num_int_ip"
    t.integer "source_num_scanners"
    t.string  "source_lms",               :limit => 10
    t.string  "source_eam",               :limit => 10
    t.integer "source_num_devices"
    t.string  "source_third_party",       :limit => 10
    t.string  "source_service_name",      :limit => 60
    t.string  "source_sia",               :limit => 10
    t.string  "source_sia_name",          :limit => 60
    t.string  "source_pci_dss",           :limit => 10
    t.string  "source_hipaa",             :limit => 10
    t.string  "source_glba",              :limit => 10
    t.integer "industry_id",                                                            :default => 0,     :null => false
    t.integer "ind_section_cd",                                                         :default => 0,     :null => false
    t.string  "ind_section_name",         :limit => 200,                                :default => "unk", :null => false
    t.string  "ind_section_short_name",   :limit => 40,                                 :default => "unk", :null => false
    t.integer "ind_division_cd",                                                        :default => 0,     :null => false
    t.string  "ind_division_name",        :limit => 200,                                :default => "unk", :null => false
    t.string  "ind_division_short_name",  :limit => 40,                                 :default => "unk", :null => false
    t.string  "cons_db_ip_string",        :limit => 20
    t.string  "cons_db_hostname",         :limit => 80
    t.string  "fw_db_ip_string",          :limit => 20
    t.string  "fw_db_hostname",           :limit => 80
    t.string  "lms_agg_ip_string",        :limit => 20
    t.string  "lms_agg_hostname",         :limit => 80
  end

end
