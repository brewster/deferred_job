require 'bundler/setup'

begin
  require 'active_support/core_ext/string/inflections'
rescue LoadError
  require 'active_support'
end

require_relative 'adapters/sidekiq_adapter'
require_relative 'adapters/generic_adapter'

module DeferredJob

  class NoSuchJob < StandardError
  end

  class Job

    attr_accessor :verbose
    attr_reader :id, :klass, :args, :set_key

    # Initialize a new DeferredJob
    # @param [String] id - The ID of the job
    # @param [Class, String] klass - The class to run
    # @param [Array] args - The arguments for the job
    def initialize(id, klass, *args)
      @id = id
      @set_key = self.class.key_for id
      @klass = klass.is_a?(String) ? klass.constantize : klass
      @args = args
    end

    # Clear all entries in the set
    def clear
      with_redis { |redis| redis.del(@set_key) }
    end

    # Clear and then remove the key for this job
    def destroy
      with_redis do |redis|
        redis.del(@set_key)
        redis.del(@id)
      end
    end

    # Determine if the set is empty
    # @return [Boolean] whether or not the set is empty
    def empty?
      count == 0
    end

    # Count the number of elements in the set
    # @return [Fixnum] the count of the elements in the set
    def count
      with_redis { |redis| redis.scard(@set_key).to_i }
    end

    # Wait for a thing before continuing
    # @param [Array] things - The things to add
    # @return [Fixnum] the number of things added
    # NOTE >= 2.4 should use sadd with multiple things
    def wait_for(*things)
      things.each do |thing|
        log "DeferredJob #{@id} will wait for #{thing.inspect}"
        with_redis { |redis| redis.sadd @set_key, thing }
      end
    end

    def waiting_for?(thing)
      with_redis { |redis| redis.sismember(@set_key, thing) }
    end

    def waiting_for
      with_redis { |redis| redis.smembers(@set_key) }
    end

    # Mark a thing as finished
    # @param [Array] things - The things to remove
    # @return [Fixnum] the number of things removed
    # NOTE >= 2.4 should use srem with multiple things
    def done(*things)
      results = nil
      with_redis do |redis|
        results = redis.multi do
          redis.scard @set_key
          things.each do |thing|
            log "DeferredJob #{id} done with #{thing.inspect}"
            redis.srem @set_key, thing
          end
          redis.scard @set_key
        end
      end
      if results.first > 0
        if results.last.zero?
          log "DeferredJob #{id} all conditions met; will now self-destruct"
          begin
            execute
          ensure
            destroy
          end
        else
          log "DeferredJob #{id} waiting on #{results.last} conditions"
        end
      end
    end

   # Don't allow new instances
    private_class_method :new

    private

    # A helper
    def with_redis(&block)
      self.class.with_redis(&block)
    end

    def adapter
      @adapter ||= get_adapter
    end

    def get_adapter
      if klass.include?(Sidekiq::Worker)
        DeferredJob::SidekiqAdapter.new
      else
        DeferredJob::GenericAdapter.new
      end
    end

    # How to log
    def log(msg)
      if verbose
        if defined?(Rails)
          Rails.logger.debug(msg)
        else
          puts msg
        end
      end
    end

    # Execute the job with the adapter
    def execute
      adapter.enqueue klass, *args
    end

    class << self

      attr_writer :redis, :key_lambda

      # The way we turn id into set_key
      # @param [Object] id - the id of the job
      # @return [String] - the set_key to use for the given id
      def key_for(id)
        lamb = @key_lambda || lambda { |id| "deferred-job:#{id}" }
        lamb.call id
      end

      # Create a new DeferredJob
      # @param [Object] id - the id of the job
      # @param [Class, String] klass - The class of the job to run
      # @param [Array] args - The args to send to the job
      # @return [DeferredJob] - the job, cleared
      def create(id, klass, *args)
        plan = [klass.to_s, args]
        with_redis { |redis| redis.set(id, MultiJson.encode(plan)) }
        # Return the job
        job = new(id, klass, *args)
        job.clear
        job
      end

      # Find an existing DeferredJob
      # @param [Object] id - the id of the job
      # @return [DeferredJob] - the job
      def find(id)
        plan_data = with_redis { |redis| redis.get(id) }
        # If found, return the job, otherwise raise NoSuchJob
        if plan_data.nil?
          raise NoSuchJob.new "No Such DeferredJob: #{id}"
        else
          plan = MultiJson.decode(plan_data)
          new(id, plan.first, *plan.last)
        end
      end

      # Determine if a give job exists
      # @param [Object] id - the id of the job to lookup
      # @return [Boolean] - whether or not the job exists
      def exists?(id)
        with_redis { |redis| !redis.get(id).nil? }
      end

      def with_redis(&block)
        block.call(@redis)
      end
    end
  end
end
