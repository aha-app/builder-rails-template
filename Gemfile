source "https://rubygems.org"

gem "rails", "~> 8.1.1"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jbuilder"
gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"
gem "inertia_rails", "~> 3.12"
gem "vite_rails", "~> 3.0"
gem "js-routes"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "annotate"
end

group :test do
  gem "sqlite3", ">= 2.1"
end
