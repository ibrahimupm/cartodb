#!/bin/bash

set -e

# Init Builder
cd /cartodb
mkdir -p /cartodb/log && chmod -R 777 /cartodb/log
createdb -T template0 -O postgres -h localhost -U postgres -E UTF8 template_postgis || true
psql -h localhost -U postgres template_postgis -c 'CREATE EXTENSION IF NOT EXISTS postgis;CREATE EXTENSION IF NOT EXISTS postgis_topology;'
REDIS_PORT=6335 RAILS_ENV=test bundle exec rake cartodb:test:prepare
cd -

# [OK] bundle exec rspec spec/commands

# [?]
# bundle exec rspec \
#   spec/models/carto/user_spec.rb \
#   spec/models/carto/user_table_spec.rb \
#   spec/models/table_spec.rb

bundle exec rspec \
  spec/requests/superadmin
