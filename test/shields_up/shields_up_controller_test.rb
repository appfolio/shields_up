require 'helper'
require 'action_controller'
require 'action_controller/test_case'
require 'rails'

module Routes
  def self.routes
    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        get '/:controller/:action', to: 'some_controller#action'
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

    def raise_params_missing_exception
      params.require(:stuff)
    end

    def action_no_protection
      saved_params = params
      params.with_shields_down do
        raise unless ShieldsUp::Parameters.param_type == params.class
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

  def test_rescue_from
    get :raise_params_missing_exception
    assert_response :bad_request
    assert_includes response.body, 'Required parameter missing: Required parameter stuff does not exist in'
  end
end

