begin
  require 'resque'

  module DeferredJob

    class ResqueAdapter

      def enqueue(klass, *args)
        ::Resque.enqueue(klass, *args)
      end

      def with_redis(&block)
        block.call(::Resque.redis)
      end
    end
  end
rescue LoadError
  # no mas
end
