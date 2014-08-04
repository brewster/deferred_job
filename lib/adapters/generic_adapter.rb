begin
  require 'sidekiq'

  module DeferredJob

    class GenericAdapter

      def enqueue(klass, *args)
        klass.enqueue(*args)
      end
    end
  end
rescue LoadError
  # no mas
end
