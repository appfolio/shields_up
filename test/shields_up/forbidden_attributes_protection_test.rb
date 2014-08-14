require 'helper'
require 'shields_up/forbidden_attributes_protection'
require 'active_model'

class ShieldsUp::ForbiddenAttributesProtectionTest < MiniTest::Unit::TestCase

  class ::Model
    include ActiveModel::MassAssignmentSecurity
    include ShieldsUp::ForbiddenAttributesProtection
    public :sanitize_for_mass_assignment
  end

  def test_controller_allowed
    setup_controller([:name])
    Model.new.sanitize_for_mass_assignment('name' => 'name')
  end

  def test_controller_forbidden
    setup_controller
    assert_raises ShieldsUp::ForbiddenAttributes do
      Model.new.sanitize_for_mass_assignment(:name => 'name')
    end
  end

  def test_controller_mixed
    setup_controller([:name])
    assert_raises ShieldsUp::ForbiddenAttributes do
      Model.new.sanitize_for_mass_assignment(:name => 'name', :id => 'id')
    end
  end

  def test_no_controller
    Model.new.sanitize_for_mass_assignment(:name => 'name')
  end

  def setup
    RequestStore.clear!
    super
  end

private

  def setup_controller(params = [])
    RequestStore.store[:permitted_for_mass_assignment] = {:Model => params}
  end
end
