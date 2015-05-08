# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_hip_session',
  :secret      => '1086e323b6d2eef26a68af65b51d1ec780590b2b2af121767fb9aa08b50cdffd3cf237c524cd3c380d7257fabf361c130dac470bf8fed9eab3404d5551394cd2'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store

# We will not use the default session table name
ActiveRecord::SessionStore::Session.set_table_name 'hip_session_v'