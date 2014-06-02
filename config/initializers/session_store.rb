# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_testmart_migrator_session',
  :secret      => '056fd63cdec130f0c464c5523bed0786f6696e20879e9045b0959c82d0523383c79d4ab057c1df42ed8aa828206ab0a506265af8c58724c43392b747969262bf'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
