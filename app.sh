#!/bin/bash
set -e

export NODE_ENV=development
export RAILS_ENV=development

bin/rails db:migrate

echo "Starting processes (Rails, Vite)"

# Start Vite dev server in the background
HMR_PROXY_PORT=30787 bin/vite dev &
VITE_PID=$!

# Trap to kill background processes on exit
trap "kill $VITE_PID 2>/dev/null" EXIT

# Start Rails in foreground
exec bin/rails s -p 8080
