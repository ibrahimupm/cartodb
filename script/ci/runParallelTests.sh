#!/bin/bash

set -ex

CARTO_POSTGRES_HOST=postgresql
CARTO_POSTGRES_PORT=5432
CARTO_POSTGRES_DIRECT_PORT=5432
CARTO_POSTGRES_USERNAME=postgres
CARTO_POSTGRES_PASSWORD=

# Avoids conflicts dropping DB & users
PARALLEL=true

# Copy database.yml
cp /cartodb/config/database.ci.yml /cartodb/config/database.yml

# Init Builder
cd /cartodb
mkdir -p /cartodb/log && chmod -R 777 /cartodb/log
createdb -T template0 -O postgres -h $CARTO_POSTGRES_HOST -U $CARTO_POSTGRES_USERNAME -E UTF8 template_postgis || true
psql -h $CARTO_POSTGRES_HOST -U $CARTO_POSTGRES_USERNAME template_postgis -c 'CREATE EXTENSION IF NOT EXISTS postgis;CREATE EXTENSION IF NOT EXISTS postgis_topology;'

# Create additional databases
bundle exec rake parallel:drop
bundle exec rake parallel:create
bundle exec rake parallel:migrate

# Copy development schema
# bundle exec rake parallel:prepare

# Setup environment from scratch
# bundle exec rake parallel:setup

bundle exec rake cartodb:db:create_publicuser
# TODO: bundle exec rake cartodb:db:create_federated_server

# Run parallel testsc
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

bundle exec rspec spec/models/carto
