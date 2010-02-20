# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_concerto_session',
  :secret => 'a26a1ba88b5bbe14111c131017105806615e0be631d5cb48622dee8b2e960b8cf3d1ed61cc4979f3b31b5546ad71bd281668663f20060f713758b3fba46e99e4'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
