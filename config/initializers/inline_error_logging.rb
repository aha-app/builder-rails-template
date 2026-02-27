module InlineErrorLogging
  def process_action(event)
    if (exception = event.payload[:exception_object])
      error = "#{exception.class} (#{exception.message}):"
      backtrace = Rails.backtrace_cleaner.clean(exception.backtrace || [])
      logger.error("\n#{error}\n\n#{backtrace.join("\n")}\n")
    end
    super
  end
end

ActionController::LogSubscriber.prepend(InlineErrorLogging)

ActionDispatch::DebugExceptions.class_eval do
  private

  def log_error(_request, _wrapper)
  end
end
