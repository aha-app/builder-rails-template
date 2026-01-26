#!/bin/bash
set -e

# Run bundle install and npm install if in production
if [ "$RAILS_ENV" = "production" ]; then
  echo "Production environment detected. Installing dependencies..."
  bundle install
  npm install
  bundle exec rake assets:precompile
else
  # Start Vite dev server in the background
  bin/vite dev &
  VITE_PID=$!

  # Trap to kill background processes on exit
  trap "kill $VITE_PID 2>/dev/null" EXIT
fi

bin/rails db:migrate

echo "Starting rails"

# Start Rails in foreground
exec bin/rails s -p 8080
