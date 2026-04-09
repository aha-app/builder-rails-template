source "https://rubygems.org"

gem "rails", "~> 8.1.2"
gem "propshaft"
gem "pg", "~> 1.6"
gem "puma", ">= 5.0"
gem "jbuilder"
gem "bcrypt", "~> 3.1.21"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue", "~> 1.3.0"
gem "solid_cable"
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"
gem "inertia_rails", "~> 3.16"
gem "vite_rails", "~> 3.0.20"
gem "js-routes"
gem "aha_builder_core", "~> 1.0.21"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", "~> 8.0.2", require: false
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "annotaterb"
end

group :test do
  gem "minitest", "~> 6.0"
  gem "sqlite3", ">= 2.1"
end
