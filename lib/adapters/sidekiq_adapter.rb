begin
  require 'sidekiq'

  module DeferredJob

    class SidekiqAdapter

      def enqueue(klass, *args)
        klass.perform_async(*args)
      end
    end
  end
rescue LoadError
  # no mas
end
