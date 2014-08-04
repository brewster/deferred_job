# DeferredJob

DeferredJob is a small library meant to work with Sidekiq or generic classes that allows
you to add a set of pre-conditions that must be met before a job kicks off.

``` bash
$ gem install deferred_job
```

## Usage

### Configuration

You'll need to tell DeferredJob which redis namespace you want to use:

``` ruby
DeferredJob::Job.redis = your_redis_instance
```

### Creating a DeferredJob

To create a deferred job, you must give it an id, and the name/arguments
of a worker to kick off when the preconditions are met:

``` ruby
job = DeferredJob::Job.create(id, SomeWorker, 'worker', 'args')
```

_NOTE:_ If you try to re-create an existing job, you'll clear it out.

### Adding preconditions

To add preconditions, you can use `#wait_for`.  So if you wanted to wait until
a few things are done, you can add them one at a time, or in bulk:

``` ruby
job.wait_for('import-1-data')
job.wait_for('import-2-data')
job.wait_for('import-1-photos', 'import-2-photos')
```

### Checking preconditions

At any time before a job executes, you can check out its preconditions with
a few inspection methods:

``` ruby
# See if we are waiting for a specific thing
job.waiting_for?('import-1-data') # true

# See what things we are waiting for
job.waiting_for # 'import-1-data', 'import-2-data', ...

# Count the number of things we're waiting for
job.count # 4

# See if we're waiting on anything at all
job.empty? # false
```

### Finishing preconditions

As you finish the preconditions, the same way you added them with `#wait_for`,
you remove them with `#done`.  When the set is empty, the job will kick
off with the args you specified in the initializer.  You don't need
to finish things in the same order you put them in (and hopefully you
aren't):

``` ruby
job.done('import-1-data')
job.done('import-1-photos', 'import-2-photos')
job.done('import-2-data') # job kick off!
```

### Loading an existing job

Most times, you'll have the need to use a `DeferredJob` in multiple
pieces of your code that don't see each other (ie: inside of your workers).
In that case, load a previous job like so:

``` ruby
# Check existence if you'd like
DeferredJob::Job.exists? id # true

# Load the job up
job = DeferredJob::Job.find id
```

_NOTE:_ If you try to find a job that does not exist, you'll raise an
exception (`DeferredJob::NoSuchJob`).

## Advanced

### Generic adapters
If you don't want DeferredJob to automatically kick off a Sidekiq job you
can instead pass in generic class with the following method:

``` ruby
def self.enqueue(*args)
````

When the deferred job is ready that method will be called instead od perform_async

### Key Generation

By default, `DeferredJob` will generate redis keys that look
like `deferred-job:#{id}`.  It can be useful to change that, so you can
specify a new lambda expression for generating the keys:

``` ruby
DeferredJob.key_lambda = lambda { |id| "job:#{id}" }
```

## License

Distributed under the MIT License.  See the attached LICENSE file.
