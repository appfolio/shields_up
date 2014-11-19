require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'rake'
require 'appraisal'
require 'rake/testtask'

namespace :test do
  Rake::TestTask.new(:all) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/shields_up/**/*_test.rb'
    test.verbose = true
  end
end

task :default => 'test:all'
