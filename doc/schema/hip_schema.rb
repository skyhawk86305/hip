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

ActiveRecord::Schema.define(:version => 20110714201837) do

  create_table "hip_asset_group", :primary_key => "hc_group_id", :force => true do |t|
    t.integer   "asset_id",                                      :null => false
    t.string    "lu_userid",    :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                  :null => false
  end

  create_table "hip_asset_group_hist", :primary_key => "hc_group_id", :force => true do |t|
    t.string    "hist_operation", :limit => 10, :null => false
    t.timestamp "hist_timestamp",               :null => false
    t.integer   "asset_id",                     :null => false
    t.string    "lu_userid",      :limit => 20, :null => false
    t.timestamp "lu_timestamp",                 :null => false
  end

  create_table "hip_config", :id => false, :force => true do |t|
    t.integer   "config_id",                                      :null => false
    t.string    "key",          :limit => 25,                     :null => false
    t.string    "value"
    t.timestamp "lu_timestamp",                                   :null => false
    t.string    "lu_userid",    :limit => 128, :default => "unk", :null => false
  end

  create_table "hip_finding_cache_element", :primary_key => "cache_set_id", :force => true do |t|
    t.integer   "row_num",                 :limit => 19, :null => false
    t.integer   "scan_id",                               :null => false
    t.integer   "finding_vid",                           :null => false
    t.integer   "asset_vid",                             :null => false
    t.timestamp "publish_ready_timestamp"
    t.string    "group_name",              :limit => 80
    t.integer   "hc_group_id"
    t.timestamp "suppress_timestamp"
    t.integer   "suppress_id"
    t.string    "valid_finding_flag",      :limit => 1,  :null => false
    t.integer   "day_of_week",                           :null => false
  end

  create_table "hip_finding_cache_set", :primary_key => "cache_set_id", :force => true do |t|
    t.string    "cache_set_status",  :limit => 8,  :null => false
    t.integer   "search_param_hash", :limit => 19, :null => false
    t.string    "in_cycle",          :limit => 1,  :null => false
    t.string    "created_by",        :limit => 20, :null => false
    t.timestamp "created_at",                      :null => false
    t.integer   "row_count",                       :null => false
    t.integer   "org_l1_id",                       :null => false
    t.integer   "org_id",                          :null => false
  end

  create_table "hip_hc_group", :primary_key => "hc_group_id", :force => true do |t|
    t.integer   "org_l1_id",                                               :null => false
    t.integer   "org_id",                                                  :null => false
    t.string    "group_name",             :limit => 80,                    :null => false
    t.string    "is_current",             :limit => 1,                     :null => false
    t.timestamp "last_current_timestamp"
    t.timestamp "created_at",                                              :null => false
    t.string    "lu_userid",              :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                            :null => false
  end

  add_index "hip_hc_group", ["org_id", "group_name"], :name => "hip_hc_group_uk1", :unique => true

  create_table "hip_hc_group_hist", :primary_key => "hc_group_id", :force => true do |t|
    t.string    "hist_operation",         :limit => 10, :null => false
    t.timestamp "hist_timestamp",                       :null => false
    t.integer   "org_l1_id",                            :null => false
    t.integer   "org_id",                               :null => false
    t.string    "group_name",             :limit => 80, :null => false
    t.string    "is_current",             :limit => 1,  :null => false
    t.timestamp "last_current_timestamp"
    t.timestamp "created_at",                           :null => false
    t.string    "lu_userid",              :limit => 20, :null => false
    t.timestamp "lu_timestamp",                         :null => false
  end

  create_table "hip_missed_scan", :primary_key => "missed_scan_id", :force => true do |t|
    t.integer   "period_id",                                               :null => false
    t.integer   "asset_id",                                                :null => false
    t.integer   "missed_scan_reason_id",                                   :null => false
    t.string    "other_explanation",     :limit => 254
    t.string    "lu_userid",             :limit => 20,  :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                            :null => false
  end

  add_index "hip_missed_scan", ["period_id", "asset_id"], :name => "hip_missed_scan_uk1", :unique => true

  create_table "hip_missed_scan_reason", :primary_key => "missed_scan_reason_id", :force => true do |t|
    t.string    "missed_scan_reason", :limit => 254,                    :null => false
    t.string    "lu_userid",          :limit => 20,  :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                         :null => false
  end

  add_index "hip_missed_scan_reason", ["missed_scan_reason"], :name => "hip_msr_uk1", :unique => true

  create_table "hip_ooc_asset_group", :primary_key => "ooc_group_id", :force => true do |t|
    t.integer   "asset_id",                                      :null => false
    t.string    "lu_userid",    :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                  :null => false
  end

  create_table "hip_ooc_group", :primary_key => "ooc_group_id", :force => true do |t|
    t.integer   "org_l1_id",                                         :null => false
    t.integer   "org_id",                                            :null => false
    t.string    "ooc_group_name",   :limit => 80,                    :null => false
    t.string    "ooc_group_status", :limit => 15,                    :null => false
    t.string    "ooc_group_type",   :limit => 20,                    :null => false
    t.timestamp "created_at",                                        :null => false
    t.string    "lu_userid",        :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                      :null => false
  end

  add_index "hip_ooc_group", ["ooc_group_name", "ooc_group_type", "org_l1_id", "org_id"], :name => "hip_ooc_group_uk1", :unique => true

  create_table "hip_ooc_group_type", :primary_key => "ooc_group_type", :force => true do |t|
    t.string    "ooc_group_type_desc", :limit => 254
    t.string    "lu_userid",           :limit => 20,  :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                          :null => false
  end

  create_table "hip_ooc_missed_scan", :primary_key => "ooc_missed_scan_id", :force => true do |t|
    t.integer   "ooc_group_id",                                           :null => false
    t.string    "ooc_scan_type",         :limit => 20,                    :null => false
    t.integer   "asset_id",                                               :null => false
    t.integer   "missed_scan_reason_id",                                  :null => false
    t.string    "lu_userid",             :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                           :null => false
  end

  add_index "hip_ooc_missed_scan", ["ooc_group_id", "ooc_scan_type", "asset_id"], :name => "hip_ooc_missed_scan_uk1", :unique => true

  create_table "hip_ooc_scan", :primary_key => "scan_id", :force => true do |t|
    t.integer   "org_l1_id",                                                :null => false
    t.integer   "org_id",                                                   :null => false
    t.integer   "ooc_group_id",                                             :null => false
    t.integer   "asset_id",                                                 :null => false
    t.integer   "tool_id",                                                  :null => false
    t.string    "tool_name",               :limit => 20,                    :null => false
    t.string    "ooc_scan_type",           :limit => 20,                    :null => false
    t.timestamp "scan_start_timestamp",                                     :null => false
    t.timestamp "publish_ready_timestamp"
    t.string    "publish_ready_userid",    :limit => 20
    t.timestamp "publish_timestamp"
    t.string    "lu_userid",               :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                             :null => false
  end

  add_index "hip_ooc_scan", ["ooc_group_id", "asset_id", "ooc_scan_type"], :name => "hip_ooc_scan_i1"

  create_table "hip_ooc_scan_finding_valid", :primary_key => "scan_id", :force => true do |t|
    t.integer   "finding_vid",                                   :null => false
    t.string    "lu_userid",    :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                  :null => false
  end

  create_table "hip_ooc_scan_type", :primary_key => "ooc_scan_type", :force => true do |t|
    t.string    "ooc_scan_type_desc",     :limit => 254
    t.string    "ooc_group_type",         :limit => 20,                     :null => false
    t.string    "ooc_scan_publish",       :limit => 1,                      :null => false
    t.string    "ooc_ecm_scan_type",      :limit => 20
    t.string    "lu_userid",              :limit => 20,  :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                             :null => false
    t.string    "file_name_abbreviation", :limit => 20
  end

  create_table "hip_period", :primary_key => "period_id", :force => true do |t|
    t.integer   "org_l1_id",                                                :null => false
    t.integer   "org_id",                                                   :null => false
    t.integer   "year",                                                     :null => false
    t.integer   "month_of_year",                                            :null => false
    t.timestamp "asset_freeze_timestamp",                                   :null => false
    t.string    "desc",                   :limit => 254
    t.string    "lu_userid",              :limit => 20,  :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                             :null => false
  end

  add_index "hip_period", ["org_l1_id", "org_id", "year", "month_of_year"], :name => "hip_period_uk1", :unique => true

  create_table "hip_period_hist", :primary_key => "period_id", :force => true do |t|
    t.string    "hist_operation",         :limit => 10,  :null => false
    t.timestamp "hist_timestamp",                        :null => false
    t.integer   "org_l1_id",                             :null => false
    t.integer   "org_id",                                :null => false
    t.integer   "year",                                  :null => false
    t.integer   "month_of_year",                         :null => false
    t.timestamp "asset_freeze_timestamp",                :null => false
    t.string    "desc",                   :limit => 254
    t.string    "lu_userid",              :limit => 20,  :null => false
    t.timestamp "lu_timestamp",                          :null => false
  end

  create_table "hip_role", :primary_key => "role_name", :force => true do |t|
    t.string    "has_associated_geo",      :limit => 1,                     :null => false
    t.string    "has_associated_org",      :limit => 1,                     :null => false
    t.string    "has_associated_category", :limit => 1,                     :null => false
    t.timestamp "created_at",                                               :null => false
    t.string    "lu_userid",               :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                             :null => false
  end

  create_table "hip_roles_bluegroup", :force => true do |t|
    t.string    "role_name",        :limit => 20,                     :null => false
    t.string    "geo",              :limit => 20
    t.string    "category",         :limit => 50
    t.integer   "org_l1_id"
    t.integer   "org_id"
    t.string    "blue_groups_name", :limit => 254,                    :null => false
    t.timestamp "created_at",                                         :null => false
    t.string    "lu_userid",        :limit => 20,  :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                       :null => false
  end

  create_table "hip_scan", :primary_key => "scan_id", :force => true do |t|
    t.integer   "period_id",                                                :null => false
    t.string    "scan_type",               :limit => 20,                    :null => false
    t.timestamp "publish_ready_timestamp"
    t.string    "publish_ready_userid",    :limit => 20
    t.timestamp "publish_timestamp"
    t.string    "lu_userid",               :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                             :null => false
  end

  create_table "hip_scan_finding", :primary_key => "asset_id", :force => true do |t|
    t.integer   "org_l1_id",                   :null => false
    t.integer   "org_id",                      :null => false
    t.integer   "org_l1_id_gen",               :null => false
    t.integer   "period_id",                   :null => false
    t.integer   "finding_id",                  :null => false
    t.string    "result",        :limit => 20, :null => false
    t.string    "lu_userid",     :limit => 20, :null => false
    t.timestamp "lu_timestamp",                :null => false
  end

  add_index "hip_scan_finding", ["org_l1_id_gen", "period_id"], :name => "sql120109175310740"
  add_index "hip_scan_finding", ["org_l1_id_gen"], :name => "sql120109175310780"
  add_index "hip_scan_finding", ["period_id"], :name => "sql120109175310770"

  create_table "hip_session", :force => true do |t|
    t.string    "session_id", :limit => 254,   :null => false
    t.string    "data",       :limit => 12000
    t.timestamp "created_at",                  :null => false
    t.timestamp "updated_at"
  end

  add_index "hip_session", ["session_id"], :name => "hip_session_x2"
  add_index "hip_session", ["updated_at"], :name => "hip_session_x1"

  create_table "hip_suppress", :primary_key => "suppress_id", :force => true do |t|
    t.integer   "org_l1_id",                                                 :null => false
    t.integer   "org_id",                                                    :null => false
    t.string    "suppress_name",           :limit => 100,                    :null => false
    t.string    "suppress_desc",           :limit => 500
    t.timestamp "start_timestamp",                                           :null => false
    t.timestamp "end_timestamp",                                             :null => false
    t.string    "suppress_class",          :limit => 25,                     :null => false
    t.string    "approval_status",         :limit => 25
    t.string    "automatic_suppress_flag", :limit => 1,                      :null => false
    t.integer   "vuln_id"
    t.string    "apply_to_scope",          :limit => 40,                     :null => false
    t.integer   "asset_id"
    t.string    "lu_userid",               :limit => 20,  :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                              :null => false
  end

  create_table "hip_suppress_finding", :primary_key => "suppress_id", :force => true do |t|
    t.integer   "finding_id",                                    :null => false
    t.string    "lu_userid",    :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                  :null => false
  end

  create_table "hip_suppress_group", :primary_key => "suppress_id", :force => true do |t|
    t.integer   "hc_group_id",                                   :null => false
    t.string    "lu_userid",    :limit => 20, :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                  :null => false
  end

  create_table "hip_task_status", :primary_key => "task_id", :force => true do |t|
    t.string    "instance_name",       :limit => 30,                     :null => false
    t.string    "task_name",           :limit => 60,                     :null => false
    t.timestamp "scheduled_timestamp",                                   :null => false
    t.string    "auto_retry",          :limit => 1,   :default => "n",   :null => false
    t.timestamp "start_timestamp",                                       :null => false
    t.timestamp "end_timestamp"
    t.string    "task_status",         :limit => 10,                     :null => false
    t.string    "task_message"
    t.string    "lu_userid",           :limit => 20,  :default => "unk", :null => false
    t.timestamp "lu_timestamp",                                          :null => false
    t.string    "params",              :limit => 254
    t.string    "class_name",          :limit => 50
  end

  create_table "meta_process_audit", :id => false, :force => true do |t|
    t.integer   "audit_id",                              :null => false
    t.timestamp "start_timestamp",                       :null => false
    t.integer   "start_yearmonth",                       :null => false
    t.timestamp "end_timestamp"
    t.integer   "process_id",                            :null => false
    t.string    "fragment",              :limit => 20
    t.integer   "batch_id",              :limit => 19
    t.string    "host_name",             :limit => 80
    t.integer   "pid"
    t.string    "status",                :limit => 10,   :null => false
    t.integer   "rc"
    t.string    "result_details",        :limit => 2000
    t.integer   "group_batch_id",        :limit => 19
    t.string    "external_batch_system", :limit => 10
    t.string    "external_batch_id",     :limit => 40
  end

  add_index "meta_process_audit", ["start_yearmonth"], :name => "sql120109175319310"

  create_table "meta_process_audit_exception", :id => false, :force => true do |t|
    t.integer   "audit_id",                                 :null => false
    t.integer   "process_id",                               :null => false
    t.timestamp "start_timestamp",                          :null => false
    t.integer   "start_yearmonth",                          :null => false
    t.string    "log_type",                  :limit => 10,  :null => false
    t.integer   "rule_order",                               :null => false
    t.string    "rule_name",                 :limit => 30,  :null => false
    t.string    "rule_scope",                :limit => 10,  :null => false
    t.string    "rule_result",               :limit => 10,  :null => false
    t.integer   "rule_reference_row_number",                :null => false
    t.integer   "rule_reference_col_number",                :null => false
    t.string    "rule_reference_col_name",   :limit => 40
    t.string    "rule_result_details",       :limit => 512
  end

  add_index "meta_process_audit_exception", ["start_yearmonth"], :name => "sql120109175319810"

end
