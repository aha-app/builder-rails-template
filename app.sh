#!/bin/bash
set -e

export NODE_ENV=development
export RAILS_ENV=development

# Ensure configuration is up to date
bundle install
npm install
bin/rails db:migrate

echo "Starting processes (Rails, Vite)"

# Start Vite dev server in the background
bin/vite dev &
VITE_PID=$!

# Trap to kill background processes on exit
trap "kill $VITE_PID 2>/dev/null" EXIT

# Start Rails in foreground
exec bin/rails s -p 8080
