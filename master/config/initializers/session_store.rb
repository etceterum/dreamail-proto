# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_master_session',
  :secret      => '3e27c741b82c298d9b03d6e18839edaa9177c955d99bebb2be95d5b7abaeaa6dd41954bc4e7fab00da6faf306cc7c6981b521105df6bdaf3fd454fb4470714a5'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
