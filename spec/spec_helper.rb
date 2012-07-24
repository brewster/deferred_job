require_relative '../lib/deferred_job'

class SomethingWorker
  @queue = :high
end
