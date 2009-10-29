# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_whatdotheyknow_session',
  :secret      => '591c05b36f63193c9fcdd3e874240e8c2dee09579353a3b421e98185a3742159db906d3075094aee1c196242d526b3d0a6d04f3ad8f06adc9599f09a1f2a14e3'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
