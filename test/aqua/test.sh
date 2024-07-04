#!/usr/bin/env bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "aqua version" aqua --version

# Report result
reportResults
