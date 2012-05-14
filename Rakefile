# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "game-server"
  gem.homepage = "http://github.com/blimp666/game-server"
  gem.license = "MIT"
  gem.summary = %Q{simply game server}
  gem.description = %Q{siply general-porpuse game server}
  gem.email = "nobody@nowhere.com"
  gem.authors = ["V_M"]
  # dependencies defined in Gemfile

  gem.files.include 'lib/game_server.rb'
  gem.files.include 'lib/base_listner.rb'
  gem.files.include 'lib/daemon_logger.rb'
  gem.files.include 'lib/game_server.rb'
  gem.files.include 'lib/request_parser.rb'
  gem.files.include 'lib/request.rb'
  gem.files.include 'lib/server_error.rb'
  gem.files.include 'lib/server_starter.rb'
  gem.files.include 'lib/object_space.rb'
  gem.files.include 'lib/game_error.rb'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

# require 'rcov/rcovtask'
# Rcov::RcovTask.new do |test|
#   test.libs << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
#   test.rcov_opts << '--exclude "gems/*"'
# end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "game-server #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
