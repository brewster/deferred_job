require 'simplecov'
require 'redis-namespace'

SimpleCov.start

require_relative '../lib/deferred_job'

DeferredJob::Job.redis = Redis::Namespace.new("deferred_job_test")

class SomethingWorker

  def self.enqueue
  end
end
