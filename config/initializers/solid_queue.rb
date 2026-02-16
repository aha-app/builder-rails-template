Rails.application.config.after_initialize do
  next unless defined?(SolidQueue)

  silence = lambda do |&block|
    if ActiveRecord::Base.logger
      ActiveRecord::Base.logger.silence(&block)
    else
      block.call
    end
  end

  SolidQueue::Processes::Registrable.prepend(Module.new do
    define_method(:heartbeat) do
      silence.call { super() }
    end
  end)

  SolidQueue::Dispatcher::ConcurrencyMaintenance.prepend(Module.new do
    define_method(:expire_semaphores) do
      silence.call { super() }
    end

    define_method(:unblock_blocked_executions) do
      silence.call { super() }
    end
  end)

  SolidQueue::Process::Prunable.prepend(Module.new do
    define_method(:prune) do
      silence.call { super() }
    end
  end)
end
