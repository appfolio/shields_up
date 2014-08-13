# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'af_strong_parameters/version'

Gem::Specification.new do |s|
  s.name          = 'af_strong_parameters'
  s.version       = AfStrongParameters::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['AppFolio']
  s.email         = 'dev@appfolio.com'
  s.description   = 'Strong_parameters made by AppFolio Inc.'
  s.summary       = s.description
  s.homepage      = 'http://github.com/appfolio'
  s.licenses      = ['MIT']

  s.files         = Dir['**/*'].reject{ |f| f[%r{^pkg/}] || f[%r{^test/}] }  
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.require_paths = ['lib']
end
