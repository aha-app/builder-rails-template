# frozen_string_literal: true

require "rails/generators"

class AhaBlobStorageGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  def install_active_storage
    run "bin/rails active_storage:install"
  end

  def add_aws_sdk_gem
    gem "aws-sdk-s3", require: false unless gem_exists?("aws-sdk-s3")
  end

  def update_storage_yml
    template "storage.yml.tt", "config/storage.yml", force: true
  end

  def update_development_environment
    gsub_file "config/environments/development.rb",
      /config\.active_storage\.service\s*=\s*:\w+/,
      "config.active_storage.service = :blob"
  end

  def update_production_environment
    gsub_file "config/environments/production.rb",
      /config\.active_storage\.service\s*=\s*:\w+/,
      "config.active_storage.service = :blob"
  end

  def display_instructions
    say "\nBlob storage configured!", :green
  end

  private

  def gem_exists?(gem_name)
    File.read("Gemfile").include?(gem_name)
  end
end
