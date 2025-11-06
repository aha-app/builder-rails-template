# config/initializers/plain_errors.rb
if defined?(PlainErrors)
  PlainErrors.configure do |config|
    config.enabled = Rails.env.development?
    config.show_code_snippets = true
    config.code_lines_context = 2
    config.trigger_headers = [ "X-Plain-Errors", "X-LLM-Request" ]
  end

  # IMPORTANT: Must use insert_before ActionDispatch::ShowExceptions
  # Rails includes ShowExceptions by default which catches all exceptions.
  Rails.application.config.middleware.insert_before ActionDispatch::ShowExceptions, PlainErrors::Middleware
end
