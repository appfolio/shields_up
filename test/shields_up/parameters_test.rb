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
      params = Parameters.new({'a' => ['b', 'c', 1],'foo' => 'bar', 'hashes' => {'can' => {'be' => 'nested'}}}, @controller)
      expected = 'bar'
      assert_equal expected, params[:foo]
      assert_equal params[:foo].class, String
      expected = {:can => {:be => 'nested'}}
      assert_equal expected, params[:hashes].instance_variable_get(:@params)
      assert_equal params[:hashes].class, ShieldsUp::Parameters
      assert_nil params[:doesntexist]
      expected = ['b', 'c']
      assert_equal expected, params[:a]
    end

    def test_permit_non_permitted_scalar
      object = Controller.new
      params = Parameters.new({'foo' => object}, @controller)
      expected = {}
      assert_equal expected, params.permit(:foo)
    end

    def test_permit_array
      params = Parameters.new({'foo' => ['1', '2', '3', 1]}, @controller)
      expected = {:foo => ['1', '2', '3']}
      assert_equal expected, params.permit(:foo => [])
      expected = {}
      assert_equal expected, params.permit(:foo)
    end

    def test_permit_hash
      params = Parameters.new({'foo' => 'bar'}, @controller)
      expected = {:foo => 'bar'}
      assert_equal expected, params.permit(:foo)
    end

    def test_permit_hash_nested
      params = Parameters.new({'foo' => {'bar' => {'name' => 'pirats', 'number' => '5', 'secret' => '1337'}}}, @controller)
      expected = {:foo => {:bar => {:name => 'pirats', :number => '5'}}}
      assert_equal expected, params.permit(:foo => [:bar => [:name, :number]])
    end

    def test_require
      params = Parameters.new({'foo' => 'bar'}, @controller)
      expected = 'bar'
      assert_equal expected, params.require(:foo)
    end

    def test_require_uses_internal_access
      params = Parameters.new({'foo' => 'bar'}, @controller)
      params.expects(:[]).with(:foo).returns('bar')
      expected = 'bar'
      assert_equal expected, params.require(:foo)
    end

    def test_require_nested
      params = Parameters.new({'foo' => {'bar' => 'baz'}}, @controller)
      expected = 'baz'
      assert_equal expected, params.require(:foo).require(:bar)
    end

    def test_require_raises
      params = Parameters.new({}, @controller)
      assert_raises ParameterMissing do
        params.require(:foo)
      end
    end

    def test_with_shields_Down
      setup_parameters(Parameters.new(ActiveSupport::HashWithIndifferentAccess.new('param' => 1), @controller))
      saved = @controller.params
      assert_nil @controller.params['param']
      assert_nil @controller.params[:param]
      assert_equal ShieldsUp::Parameters, @controller.params.class
      @controller.params.with_shields_down do
        assert_equal 1, @controller.params['param']
        assert_equal 1, @controller.params[:param]
        assert_equal ActiveSupport::HashWithIndifferentAccess, @controller.params.class
      end
      assert_nil @controller.params['param']
      assert_nil @controller.params[:param]
      assert_equal ShieldsUp::Parameters, @controller.params.class
      assert_equal saved, @controller.params
    end

    private

    def setup_parameters(params)
      @controller.params = params
    end
  end
end
