bundle install

bin/rails db:migrate

echo "Starting processes (Rails, Tailwind)"

bin/rails s -p 8080 &
RAILS_PID=$!

# Start tailwind watcher if available (fall back to build if not)
if bin/rails list | grep -q tailwindcss:watch 2>/dev/null; then
	bin/rails tailwindcss:watch &
	TAILWIND_PID=$!
else
	echo "tailwindcss:watch task not found; running build once"
	if bin/rails list | grep -q tailwindcss:build 2>/dev/null; then
		bin/rails tailwindcss:build || true
	fi
fi

wait $RAILS_PID ${TAILWIND_PID:-}
