require File.dirname(__FILE__) + '/../spec_helper'

describe DeferredJob::Job do

  describe :find do

    it 'should raise error when finding a DeferredJob that does not exist' do
      lambda do
        DeferredJob::Job.find('nosuchkey')
      end.should raise_error DeferredJob::NoSuchJob
    end

    it 'should be able to find a job' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job = DeferredJob::Job.find('something')
      job.klass.should == SomethingWorker
    end

    it 'should be able to find a with args' do
      job = DeferredJob::Job.create('something', SomethingWorker, 'a1', 'a2')
      job = DeferredJob::Job.find('something')
      job.args.should == ['a1', 'a2']
    end

    it 'should be able to find a job with things' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.wait_for 'thing'
      job = DeferredJob::Job.find('something')
      job.count.should == 1
    end

  end

  describe :exists do

    let(:id) { '1' }
    let!(:job) { DeferredJob::Job.create(id, SomethingWorker) }

    it 'should return true when the job exists' do
      DeferredJob::Job.exists?(id).should be_true
    end

    it 'should return false when the job does not exist' do
      DeferredJob::Job.exists?(id + 'a').should be_false
    end

  end

  describe :done do

    it 'should decrement when told something is done' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.done 'thing'
      job.should be_empty
    end

    it 'should execute when empty after done' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.should_receive(:execute).once.and_return(nil)
      job.done 'thing'
    end

    it 'should return false if job not executed' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.wait_for 'thing2'
      job.done('thing').should be_false
    end
    it 'should return true after executing' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.done('thing').should be_true
    end

  end

  describe :wait_for do

    it 'should add one that its waiting for' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.count.should == 1
    end

    it 'should add multiple things' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.wait_for 'thing1'
      job.wait_for 'thing2'
      job.count.should == 2
    end

    it 'should not add the same thing twice' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.wait_for 'thing'
      job.count.should == 1
    end

    it 'should be able to add multiple things at a time' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.wait_for 'thing1', 'thing2'
      job.count.should == 2
    end

  end

  describe :waiting_for? do

    let(:id) { 1 }
    let(:job) { DeferredJob::Job.create(id, SomethingWorker) }

    let(:thing) { 'hello' }
    before do
      job.wait_for thing
    end

    it 'should be true for things its waiting for' do
      job.waiting_for?(thing).should be_true
    end

    it 'should be false for things its not waiting for' do
      job.waiting_for?(thing + 'a').should be_false
    end

  end

  describe :waiting_for? do

    let(:id) { 1 }
    let(:job) { DeferredJob::Job.create(id, SomethingWorker) }

    context 'when waiting for something' do

      let(:thing) { 'hello' }
      before do
        job.wait_for thing
      end

      it 'should be true for things its waiting for' do
        job.waiting_for.should == [thing]
      end

    end

    context 'when waiting for nothing' do

      it 'should return an empty array' do
        job.waiting_for.should == []
      end

    end

  end

  describe :create do

    it 'should be able to create a new job' do
      job1 = DeferredJob::Job.create('something', SomethingWorker)
      job2 = DeferredJob::Job.find("something")
      job1.id.should == job2.id
    end

    it 'should clear previously existing on create' do
      job = DeferredJob::Job.create('something', SomethingWorker)
      job = DeferredJob::Job.create('something', SomethingWorker)
      job.count.should == 0
    end

  end

  describe :new do

    it 'should not be able to use new' do
      lambda do
        DeferredJob::Job.new
      end.should raise_error NoMethodError
    end

  end

  describe :key_lambda do

    let(:id) { 1 }
    let(:job) { DeferredJob::Job.create(id, SomethingWorker) }
    let(:subject) { job.set_key }

    before do
      DeferredJob::Job.key_lambda = lamb
    end

    context 'with default key lambda' do

      let(:lamb) { nil }

      it 'should be built the default way' do
        should == "deferred-job:#{id}"
      end

    end

    context 'with changed key lambda' do

      let(:lamb) { lambda { |i| i } }

      it 'should be built with the custom lambda' do
        should == id
      end

    end

  end

end
