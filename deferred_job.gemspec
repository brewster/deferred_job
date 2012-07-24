spec = Gem::Specification.new do |s|
  s.name = 'deferred_job'
  s.author = 'John Crepezzi'
  s.description = 'Resque Deferred Jobs'
  s.email = 'john@brewster.com'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'activesupport'
  s.add_dependency 'multi_json'
  s.add_dependency 'resque'
  s.files = Dir['lib/**/*.rb'] + ['README.md']
  s.homepage = 'http://github.com/brewster/deferred_job'
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.summary = 'Resque Deferred Job Library'
  s.test_files = Dir.glob('spec/*.rb')
  s.version = '0.0.1' # TODO
end
