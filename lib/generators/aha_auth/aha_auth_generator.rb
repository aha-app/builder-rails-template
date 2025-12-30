# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

class AhaAuthGenerator < Rails::Generators::Base
  include ActiveRecord::Generators::Migration

  source_root File.expand_path("templates", __dir__)

  argument :attributes, type: :array, default: [], banner: "field[:type] field[:type]"

  class_option :skip_migration, type: :boolean, default: false, desc: "Skip migration generation"

  def generate_migration_file
    return if options[:skip_migration]

    migration_template "migration.rb.tt", File.join(db_migrate_path, "create_users.rb")
  end

  def create_user_model
    template "user.rb.tt", "app/models/user.rb"
  end

  def create_current_model
    template "current.rb.tt", "app/models/current.rb"
  end

  def create_sessions_controller
    template "sessions_controller.rb.tt", "app/controllers/sessions_controller.rb"
  end

  def create_authentication_concern
    template "authentication.rb.tt", "app/controllers/concerns/authentication.rb"
  end

  def add_routes
    route <<~RUBY
      get "login", to: "sessions#new", as: :new_session
      get "callback", to: "sessions#callback", as: :session_callback
      delete "logout", to: "sessions#logout", as: :logout
    RUBY
  end

  def add_inertia_auth_share
    return unless File.exist?("app/controllers/inertia_controller.rb")

    inject_into_file "app/controllers/inertia_controller.rb",
      after: "inertia_share flash: -> { flash.to_hash }\n" do
      <<-RUBY
  inertia_share auth: -> {
    {
      user: current_user&.as_json(only: %i[id email first_name last_name])
    }
  }
      RUBY
    end
  end

  def add_authentication_to_application_controller
    inject_into_file "app/controllers/application_controller.rb",
      after: "class ApplicationController < ActionController::Base\n" do
      "  include Authentication\n"
    end
  end

  def add_typescript_types
    types_file = "app/frontend/types/index.ts"
    return unless File.exist?(types_file)

    gsub_file types_file,
      /export interface Flash \{\n  alert\?: string;\n  notice\?: string;\n\}\n\nexport interface SharedData \{\n  flash: Flash;\n\}/,
      <<~TYPESCRIPT.chomp
        export interface Flash {
          alert?: string
          notice?: string
        }

        export interface AuthUser {
          id: number
          email: string
          first_name: string | null
          last_name: string | null
        }

        export interface SharedData {
          flash: Flash
          auth: {
            user: AuthUser | null
          }
        }
      TYPESCRIPT
  end

  def generate_js_routes
    rails_command "js:routes"
  end

  def display_instructions
    say "\nAha Auth setup complete!", :green
    say "\nNext step:"
    say "  rails db:migrate"
  end

  private

  def auth_attributes
    %w[
      auth_identifier:string
      email:string
      first_name:string
      last_name:string
      email_verified:boolean
    ]
  end

  def all_attributes
    @all_attributes ||= (auth_attributes + attributes.map(&:to_s)).map do |attr|
      Rails::Generators::GeneratedAttribute.parse(attr)
    end
  end

  def custom_attributes
    @custom_attributes ||= attributes.map do |attr|
      Rails::Generators::GeneratedAttribute.parse(attr.to_s)
    end
  end

  def migration_class_name
    "CreateUsers"
  end

  def table_name
    "users"
  end
end
