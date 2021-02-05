#!/bin/bash

set -e

WORKERS=${1:-22}

# init builder
script/ci/init.sh

# BACKEND PARALLEL
script/ci/generateSpecFull.sh

# CLEANER
script/ci/cleaner.sh

# WRAPPER
script/ci/wrapper.sh $WORKERS

# TESTS
time parallel -j $WORKERS -a parallel_tests/specfull.txt 'script/ci/executor.sh {} {%} {#}'

# REPORTER
script/ci/reporter.sh
