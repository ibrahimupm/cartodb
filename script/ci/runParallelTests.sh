#!/bin/bash

set -e

# Copy database.yml
cp /cartodb/config/database.ci.yml /cartodb/config/database.yml

# Init Builder
cd /cartodb
mkdir -p /cartodb/log && chmod -R 777 /cartodb/log
createdb -T template0 -O postgres -h localhost -U postgres -E UTF8 template_postgis || true
psql -h localhost -U postgres template_postgis -c 'CREATE EXTENSION IF NOT EXISTS postgis;CREATE EXTENSION IF NOT EXISTS postgis_topology;'
REDIS_PORT=6335 RAILS_ENV=test bundle exec rake cartodb:test:prepare
cd -

# Create additional databases
bundle exec rake parallel:create

# Copy development schema
bundle exec rake parallel:prepare

# Run migrations
bundle exec rake parallel:migrate

# Setup environment from scratch
bundle exec rake parallel:setup

# Run parallel tests
bundle exec rake parallel:spec['spec\/models']

# [OK] bundle exec rspec spec/commands

# [OK]
# bundle exec rspec \
#   spec/models/carto/user_spec.rb \
#   spec/models/carto/user_table_spec.rb \
#   spec/models/table_spec.rb

# [?]
# bundle exec rspec \
#   spec/requests/superadmin
