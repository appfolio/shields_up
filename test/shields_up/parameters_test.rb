require 'helper'

module ShieldsUp
  class ParametersTest < MiniTest::Unit::TestCase
    class Controller
      attr_accessor :params
    end

    def setup
      super
      @controller = Controller.new
    end

    def test_access
      params = Parameters.new({'foo' => 'bar', 'hashes' => {'can' => {'be' => 'nested'}}}, @controller)
      expected = 'bar'
      assert_equal expected, params[:foo]
      assert_equal params[:foo].class, String
      expected = {:can => {:be => 'nested'}}
      assert_equal expected, params[:hashes].instance_variable_get(:@params)
      assert_equal params[:hashes].class, ShieldsUp::Parameters
      assert_nil params[:doesntexist]
    end

    def test_access_array
      obejct = Controller.new
      params = Parameters.new({'foo' => obejct}, @controller)
      expected = {}
      assert_equal expected, params.permit(:foo)
      # params = Parameters.new({'foo' => [{:one => 1},{:one => 2}, {:one => 3}]}, @controller)
      # expected = [{:one => 1}, {:one => 2}, {:one => 3}]
      # assert_equal expected, params.permit([:foo] => [:one])
    end

    private

    def setup_parameters(params)
      @controller.params = params
    end
  end
end
