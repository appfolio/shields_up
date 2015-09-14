require 'codeclimate-test-reporter'
CodeClimate::TestReporter.configuration.profile

require 'minitest/autorun'
require 'mocha/setup'
require 'active_support/hash_with_indifferent_access'
require 'shields_up'

