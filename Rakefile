begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

ZIP_URL = "https://github.com/projecthydra/hydra-jetty/archive/v8.0.0.rc2.zip"

require 'active_support/benchmarkable'
require 'jettywrapper'

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Cerberus'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'engine_cart/rake_task'
task :ci => ['engine_cart:generate', 'jetty:clean'] do
  # run the tests
  RAILS_ENV = 'test'
  jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '/jetty')})
  Jettywrapper.wrap(jetty_params) do
    Rake::Task['spec'].invoke
  end
end

namespace :cerberus do
  task :server do
    jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '/jetty')})
    Jettywrapper.wrap(jetty_params) do
      within_test_app do
        system "rails s"
      end
    end
  end

  task :console do
    jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '/jetty')})
    Jettywrapper.wrap(jetty_params) do
      within_test_app do
        system "rails c"
      end
    end
  end
end


load 'rails/tasks/statistics.rake'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :ci

Bundler::GemHelper.install_tasks
