#!/bin/sh
# Started by the Lambda Web Adapter wrapper (/opt/bootstrap runs this as the handler).
set -eu

# /var/task is read-only; Bundler needs a writable home.
export HOME=/tmp
export BUNDLE_APP_CONFIG=/var/task/.bundle
export HANAMI_PORT="${AWS_LWA_PORT}"

exec bundle exec puma -C config/puma.rb
