Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]

def start
  puts">>>>>>>updating 'provider' to 'Provider' and 'superuser' to 'Superuser'"
        ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.user_role
SET role = 'Provider'
WHERE role = 'provider'
EOF

  ActiveRecord::Base.connection.execute <<EOF
UPDATE #{Source_db}.user_role
SET role = 'Superuser'
WHERE role = 'superuser'
EOF


end

start
