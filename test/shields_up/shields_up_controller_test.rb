require 'helper'
require 'action_controller'
require 'action_controller/test_case'
require 'rails'

module Routes
  def self.routes
    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        match '/:controller/:action', to: 'some_controller#action'
        match '/:controller/:action_no_protection', to: 'some_controller#action_no_protection'
      end
    end
  end
end

class ShieldsUpTest < ActionController::TestCase
  ENV['RAILS_ENV'] = 'test'
  Rails.application = class FakeApp < Rails::Application; end

  class ::FakeModel; end
  class ::AnotherFakeModel; end

  class ::SomeController < ActionController::Base
    include ShieldsUp
    include Routes.routes.url_helpers

    def action
      render :nothing => true
    end

    def action_no_protection
      saved_params = params
      params.with_shields_down do
        raise unless ShieldsUp::Parameters::PARAM_TYPE == params.class
      end
      raise unless saved_params == params
      render :nothing => true
    end
  end

  tests SomeController

  def setup
    @routes = Routes.routes
    super
  end

  def test_before_filter
    get :action
    assert_equal ShieldsUp::Parameters, @controller.params.class
  end

  def test_with_shields_down
    get :action_no_protection
    assert_equal ShieldsUp::Parameters, @controller.params.class
  end
end

