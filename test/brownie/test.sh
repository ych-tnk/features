#!/bin/bash

set -e

source dev-container-features-test-lib

check "brownie --version" brownie --version

reportResults
