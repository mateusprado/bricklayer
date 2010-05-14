# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_cloud-panel_session',
  :secret      => '4df7a570ceee3d36d26756be029d0ac23f1a79d394c1a884cc47d4c8a1dcb680f89617ceb742e838e2e21f6aead3ab6d385f9f670162e8942d44ac0692517f43'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
