require File.dirname(__FILE__) + '/../spec_helper'

describe Resque::DeferredJob do

  describe :find do

    it 'should raise an error when finding a DeferredJob that does not exist' do
      lambda do
        Resque::DeferredJob.find("nosuchkey")
      end.should raise_error Resque::NoSuchKey
    end

  end

  describe :done do 

    it 'should decrement when told something is done' do
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.done 'thing'
      job.should be_empty
    end

    it 'should execute when empty after done' do
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.should_receive(:execute).once.and_return(nil)
      job.done 'thing'
    end

  end

  describe :wait_for do

    it 'should add one that its waiting for' do
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.count.should == 1
    end

    it 'should add multiple things' do
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job.wait_for 'thing1'
      job.wait_for 'thing2'
      job.count.should == 2
    end

    it 'should not add the same thing twice' do
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job.wait_for 'thing'
      job.wait_for 'thing'
      job.count.should == 1
    end

    it 'should be able to add multiple things at a time' do
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job.wait_for 'thing1', 'thing2'
      job.count.should == 2
    end

  end

  describe :create do

    it 'should be able to create a new job' do
      job1 = Resque::DeferredJob.create('something', SomethingWorker)
      job2 = Resque::DeferredJob.find("something")
      job1.id.should == job2.id
    end

    it 'should clear previously existing on create' do
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job.count.should == 0
    end

  end

  describe :new do

    it 'should not be able to use new' do
      lambda do
        Resque::DeferredJob.new
      end.should raise_error NoMethodError
    end

    it 'should be able to find a job' do
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job = Resque::DeferredJob.find('something')
      job.klass.should == SomethingWorker
    end

    it 'should be able to find a with args' do
      job = Resque::DeferredJob.create('something', SomethingWorker, 'a1', 'a2')
      job = Resque::DeferredJob.find('something')
      job.args.should == ['a1', 'a2']
    end

    it 'should be able to find a job with things' do
      job = Resque::DeferredJob.create('something', SomethingWorker)
      job.wait_for 'thing'
      job = Resque::DeferredJob.find('something')
      job.count.should == 1
    end

  end

end
