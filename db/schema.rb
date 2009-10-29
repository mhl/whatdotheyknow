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

ActiveRecord::Schema.define(:version => 79) do

  create_table "acts_as_xapian_jobs", :force => true do |t|
    t.string  "model",    :null => false
    t.integer "model_id", :null => false
    t.string  "action",   :null => false
  end

  add_index "acts_as_xapian_jobs", ["model", "model_id"], :name => "index_acts_as_xapian_jobs_on_model_and_model_id", :unique => true

  create_table "censor_rules", :force => true do |t|
    t.integer  "info_request_id"
    t.integer  "user_id"
    t.integer  "public_body_id"
    t.text     "text",              :null => false
    t.text     "replacement",       :null => false
    t.string   "last_edit_editor",  :null => false
    t.text     "last_edit_comment", :null => false
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "comments", :force => true do |t|
    t.integer  "user_id",                                       :null => false
    t.string   "comment_type",    :default => "internal_error", :null => false
    t.integer  "info_request_id"
    t.text     "body",                                          :null => false
    t.boolean  "visible",         :default => true,             :null => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

  create_table "exim_log_dones", :force => true do |t|
    t.text     "filename",   :null => false
    t.datetime "last_stat",  :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "exim_log_dones", ["last_stat"], :name => "index_exim_log_dones_on_last_stat"

  create_table "exim_logs", :force => true do |t|
    t.integer  "exim_log_done_id"
    t.integer  "info_request_id"
    t.integer  "order",            :null => false
    t.text     "line",             :null => false
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "exim_logs", ["exim_log_done_id"], :name => "index_exim_logs_on_exim_log_done_id"

  create_table "holidays", :force => true do |t|
    t.date "day"
    t.text "description"
  end

  add_index "holidays", ["day"], :name => "index_holidays_on_day"

  create_table "incoming_messages", :force => true do |t|
    t.integer  "info_request_id",        :null => false
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.text     "cached_attachment_text"
    t.text     "cached_main_body_text"
    t.integer  "raw_email_id",           :null => false
  end

  create_table "info_request_events", :force => true do |t|
    t.integer  "info_request_id",     :null => false
    t.text     "event_type",          :null => false
    t.text     "params_yaml",         :null => false
    t.datetime "created_at",          :null => false
    t.string   "described_state"
    t.string   "calculated_state"
    t.datetime "last_described_at"
    t.integer  "incoming_message_id"
    t.integer  "outgoing_message_id"
    t.integer  "comment_id"
  end

  add_index "info_request_events", ["created_at"], :name => "index_info_request_events_on_created_at"
  add_index "info_request_events", ["info_request_id"], :name => "index_info_request_events_on_info_request_id"

  create_table "info_requests", :force => true do |t|
    t.text     "title",                                            :null => false
    t.integer  "user_id",                                          :null => false
    t.integer  "public_body_id",                                   :null => false
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.string   "described_state",                                  :null => false
    t.boolean  "awaiting_description",      :default => false,     :null => false
    t.string   "prominence",                :default => "normal",  :null => false
    t.text     "url_title",                                        :null => false
    t.string   "law_used",                  :default => "foi",     :null => false
    t.string   "allow_new_responses_from",  :default => "anybody", :null => false
    t.string   "handle_rejected_responses", :default => "bounce",  :null => false
  end

  add_index "info_requests", ["created_at"], :name => "index_info_requests_on_created_at"
  add_index "info_requests", ["title"], :name => "index_info_requests_on_title"
  add_index "info_requests", ["url_title"], :name => "index_info_requests_on_url_title", :unique => true

  create_table "outgoing_messages", :force => true do |t|
    t.integer  "info_request_id",              :null => false
    t.text     "body",                         :null => false
    t.string   "status",                       :null => false
    t.string   "message_type",                 :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.datetime "last_sent_at"
    t.integer  "incoming_message_followup_id"
    t.string   "what_doing",                   :null => false
  end

  add_index "outgoing_messages", ["what_doing"], :name => "index_outgoing_messages_on_what_doing"

  create_table "post_redirects", :force => true do |t|
    t.text     "token",                                    :null => false
    t.text     "uri",                                      :null => false
    t.text     "post_params_yaml"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.text     "email_token",                              :null => false
    t.text     "reason_params_yaml"
    t.integer  "user_id"
    t.text     "circumstance",       :default => "normal", :null => false
  end

  add_index "post_redirects", ["email_token"], :name => "index_post_redirects_on_email_token"
  add_index "post_redirects", ["token"], :name => "index_post_redirects_on_token"
  add_index "post_redirects", ["updated_at"], :name => "index_post_redirects_on_updated_at"

  create_table "profile_photos", :force => true do |t|
    t.binary  "data",    :null => false
    t.integer "user_id", :null => false
  end

  create_table "public_bodies", :force => true do |t|
    t.text     "name",                                              :null => false
    t.text     "short_name",                                        :null => false
    t.text     "request_email",                                     :null => false
    t.integer  "version",                                           :null => false
    t.string   "last_edit_editor",                                  :null => false
    t.text     "last_edit_comment",  :limit => 255,                 :null => false
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.text     "url_name",                                          :null => false
    t.text     "home_page",                         :default => "", :null => false
    t.text     "notes",                             :default => "", :null => false
    t.string   "first_letter",                                      :null => false
    t.text     "publication_scheme",                :default => "", :null => false
    t.text     "charity_number",                    :default => "", :null => false
  end

  add_index "public_bodies", ["first_letter"], :name => "index_public_bodies_on_first_letter"
  add_index "public_bodies", ["url_name"], :name => "index_public_bodies_on_url_name", :unique => true

  create_table "public_body_tags", :force => true do |t|
    t.integer  "public_body_id", :null => false
    t.text     "name",           :null => false
    t.datetime "created_at",     :null => false
  end

  add_index "public_body_tags", ["public_body_id", "name"], :name => "index_public_body_tags_on_public_body_id_and_name", :unique => true

  create_table "public_body_versions", :force => true do |t|
    t.integer  "public_body_id"
    t.integer  "version"
    t.text     "name"
    t.text     "short_name"
    t.text     "request_email"
    t.datetime "updated_at"
    t.string   "last_edit_editor"
    t.text     "last_edit_comment",  :limit => 255
    t.text     "url_name"
    t.text     "home_page"
    t.text     "notes"
    t.text     "publication_scheme",                :default => "", :null => false
    t.text     "charity_number",                    :default => "", :null => false
  end

  create_table "raw_emails", :force => true do |t|
    t.text "data", :null => false
  end

  create_table "track_things", :force => true do |t|
    t.integer  "tracking_user_id",                               :null => false
    t.string   "track_query",                                    :null => false
    t.integer  "info_request_id"
    t.integer  "tracked_user_id"
    t.integer  "public_body_id"
    t.string   "track_medium",                                   :null => false
    t.string   "track_type",       :default => "internal_error", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "track_things", ["tracking_user_id", "track_query"], :name => "index_track_things_on_tracking_user_id_and_track_query", :unique => true

  create_table "track_things_sent_emails", :force => true do |t|
    t.integer  "track_thing_id",        :null => false
    t.integer  "info_request_event_id"
    t.integer  "user_id"
    t.integer  "public_body_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "track_things_sent_emails", ["track_thing_id"], :name => "index_track_things_sent_emails_on_track_thing_id"

  create_table "user_info_request_sent_alerts", :force => true do |t|
    t.integer "user_id",               :null => false
    t.integer "info_request_id",       :null => false
    t.string  "alert_type",            :null => false
    t.integer "info_request_event_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                                     :null => false
    t.string   "name",                                                      :null => false
    t.string   "hashed_password",                                           :null => false
    t.string   "salt",                                                      :null => false
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
    t.boolean  "email_confirmed",        :default => false,                 :null => false
    t.text     "url_name",                                                  :null => false
    t.datetime "last_daily_track_email", :default => '2000-01-01 00:00:00'
    t.string   "admin_level",            :default => "none",                :null => false
    t.text     "ban_text",               :default => "",                    :null => false
    t.integer  "profile_photo_id"
  end

  add_index "users", ["url_name"], :name => "index_users_on_url_name", :unique => true

end
