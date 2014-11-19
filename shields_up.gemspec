# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shields_up/version'

Gem::Specification.new do |s|
  s.name          = 'shields_up'
  s.version       = ShieldsUp::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['AppFolio']
  s.email         = 'dev@appfolio.com'
  s.description   = 'Mass assignment Protection made by AppFolio Inc., inspired by strong_parameters.'
  s.summary       = s.description
  s.homepage      = 'http://github.com/appfolio/shields_up'
  s.licenses      = ['MIT']

  s.files         = Dir['**/*'].reject{ |f| f[%r{^pkg/}] || f[%r{^test/}] }
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.require_paths = ['lib']
  s.add_dependency('activesupport', ['>= 3.2', '< 4.1'])
end
