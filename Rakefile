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
require 'af_gems/gem_tasks'
require 'af_gems/appraisal'

namespace :test do
  Rake::TestTask.new(:units) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/af_job/**/*_test.rb'
    test.verbose = true
  end

  Rake::TestTask.new(:functionals) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/functional/**/*_test.rb'
    test.verbose = true
  end

  AfGems::RubyAppraisalTask.new(:all, [ 'ruby-2.0.0', 'ruby-2.1.2' ])

end


desc 'Test the af_strong_paramaters plugin.'

task :test => ["test:units", "test:functionals"]

task :default => :test
