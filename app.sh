#!/bin/bash
set -e

# One-time setup
bundle install
bin/rails db:migrate

echo "Starting processes (Rails, Tailwind)"

# Set environment variable and run Rails in foreground
# Tailwind starts as a plugin in Puma
export TAILWIND_WATCH_ARG="[poll]"
exec bin/rails s -p 8080
