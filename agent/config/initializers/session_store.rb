# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_agent_session',
  :secret      => 'dd15e566619e28c84f40366cd73d68b590ae3c3ec5057debc449e9a21b322c37f28c8b7f100337009336b7e9461cf13ce0afeca3edaddcf7ffe29c6f4a986c62'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
