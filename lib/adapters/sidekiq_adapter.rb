begin
  require 'sidekiq'

  module DeferredJob

    class SidekiqAdapter

      def enqueue(klass, *args)
        klass.perform_async(*args)
      end

      def with_redis(&block)
        Sidekiq.redis(&block)
      end
    end
  end
rescue LoadError
  # no mas
end
