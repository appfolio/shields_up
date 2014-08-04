require 'helper'

class AfStrongParameters::ForbiddenAttributesProtectionTest < MiniTest::Unit::TestCase

  class FaketiveRecord
    def sanitize_for_mass_assignment(*args)
    end
  end

  class Test < FaketiveRecord
    include AfStrongParameters::ForbiddenAttributesProtection
  end

  def test_sanitize_for_mass_assignment_controller_permitted_false
    setup_record(true)
    assert_raises AfStrongParameters::ForbiddenAttributes do
      @record.sanitize_for_mass_assignment(params_mock_false)
    end
  end

  def test_sanitize_for_mass_assignment_controller_permitted_true
    setup_record(true)
    FaketiveRecord.any_instance.expects(:sanitize_for_mass_assignment)
    @record.sanitize_for_mass_assignment(params_mock_true)
  end

  def test_sanitize_for_mass_assignment_controller_no_permitted_function
    setup_record(true)
    assert_raises AfStrongParameters::ForbiddenAttributes do
      @record.sanitize_for_mass_assignment(params_mock_no_method)
    end
  end

  def test_sanitize_for_mass_assignment_no_controller_allows_mass_assignment
    setup_record(false, 2)
    FaketiveRecord.any_instance.expects(:sanitize_for_mass_assignment).twice
    [params_mock_true, params_mock_no_method].each do |mock|
      @record.sanitize_for_mass_assignment(mock)
    end
  end

private

  def setup_record(from_controller, num = 1)
    @record = AfStrongParameters::ForbiddenAttributesProtectionTest::Test.new
    @record.expects(:coming_from_controller).returns(from_controller).times(num)
  end

  def params_mock_true
    mock(:permitted? => true)
  end

  def params_mock_false
    mock(:permitted? => false)
  end

  def params_mock_no_method
    mock
  end
end
