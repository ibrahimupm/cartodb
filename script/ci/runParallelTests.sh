#!/bin/bash

set -e

# Init Builder
cd /cartodb
mkdir -p /cartodb/log && chmod -R 777 /cartodb/log
createdb -T template0 -O postgres -h localhost -U postgres -E UTF8 template_postgis || true
psql -h localhost -U postgres template_postgis -c 'CREATE EXTENSION IF NOT EXISTS postgis;CREATE EXTENSION IF NOT EXISTS postgis_topology;'
REDIS_PORT=6335 RAILS_ENV=test bundle exec rake cartodb:test:prepare
cd -

bundle exec rspec spec/commands

# WRAPPER
# script/ci/wrapper.sh $WORKERS

# TESTS
# time parallel -j $WORKERS -a parallel_tests/specfull.txt 'script/ci/executor.sh {} {%} {#}'

# REPORTER
# script/ci/reporter.sh
