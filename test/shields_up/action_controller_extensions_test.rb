require 'helper'
require 'shields_up/action_controller_extensions'
require 'action_controller'
require 'action_controller/test_case'
require 'rails'

module Routes
  def self.routes
    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        match '/:controller/:action', to: 'some_controller#action'
        match '/:controller/:action_with_permit', to: 'some_controller#action_with_permit'
      end
    end
  end
end

class ShieldsUp::ActionControllerExtensionsTest < ActionController::TestCase
  ENV['RAILS_ENV'] = 'test'
  Rails.application = class FakeApp < Rails::Application; end

  class ::FakeModel; end
  class ::AnotherFakeModel; end

  class ::SomeController < ActionController::Base
    include ShieldsUp::ActionControllerExtensions
    include Routes.routes.url_helpers

    def action
      render :nothing => true
    end

    def action_with_permit
      permit_for_model(FakeModel, [:name, :foobar])
      permit_for_model(AnotherFakeModel, [:name])
      permit_for_model(AnotherFakeModel, [:baz])
      permit_for_model(AnotherFakeModel, [:baz])
      render :nothing => true
    end
  end

  tests SomeController

  def setup
    RequestStore.clear!
    @routes = Routes.routes
    super
  end

  def test_before_filter
    get :action
    assert_equal({}, RequestStore.store[:permitted_for_mass_assignment])
  end

  def test_permit_for_model
    get :action_with_permit
    expected = {:FakeModel => [:name, :foobar], :AnotherFakeModel => [:baz, :name]}
    assert_equal(expected, RequestStore.store[:permitted_for_mass_assignment])
    assert_equal(expected, @controller.permitted)
    assert_equal([:name, :foobar], @controller.permitted_for_model(FakeModel))
    assert_equal([:baz, :name], @controller.permitted_for_model(AnotherFakeModel))
  end

  def test_permitted_assignment_is_private
    controller = SomeController.new
    assert_raises NoMethodError do
      controller.permitted = 'value'
    end
  end
end

