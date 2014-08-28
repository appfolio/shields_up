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
      expected = ['b', 'c', 1]
      assert_equal expected, params[:a]
    end

    def test_permit_non_permitted_scalar
      object = Controller.new
      params = Parameters.new({'foo' => object}, @controller)
      expected = {}
      assert_equal expected, params.permit(:foo)
    end

    def test_permit_array
      object = Controller.new
      params = Parameters.new({'foo' => ['1', '2', '3', 1, object]}, @controller)
      expected = {:foo => ['1', '2', '3', 1]}
      assert_equal expected, params.permit(:foo => [])
      expected = {}
      assert_equal expected, params.permit(:foo)
    end

    def test_permit_legal_array
      object = Controller.new
      params = Parameters.new({'foo' => ['1', '2', '3', 1]}, @controller)
      expected = {:foo => ['1', '2', '3', 1]}
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
      object = Controller.new
      setup_parameters(Parameters.new(ActiveSupport::HashWithIndifferentAccess.new('param' => object), @controller))
      saved = @controller.params
      assert_nil @controller.params['param']
      assert_nil @controller.params[:param]
      assert_equal ShieldsUp::Parameters, @controller.params.class
      @controller.params.with_shields_down do
        assert_equal object, @controller.params['param']
        assert_equal object, @controller.params[:param]
        assert_equal ActiveSupport::HashWithIndifferentAccess, @controller.params.class
      end
      assert_nil @controller.params['param']
      assert_nil @controller.params[:param]
      assert_equal ShieldsUp::Parameters, @controller.params.class
      assert_equal saved, @controller.params
    end

    def test_permit_for_array_of_hashes

      params = Parameters.new({'bar' => [{'foo2' => 2}, {'foo3' => 'bar3'}]}, @controller)
      expected = {:bar=>[{:foo2=>2}, {}]}
      assert_equal expected, params.permit(:bar => [:foo2])
    end

    def test_get_for_array_of_hashes
      params = Parameters.new({'bar' => [{'foo2' => 'bar2'}, {'foo3' => 'bar3'}]}, @controller)
      e1 = Parameters.new({:foo2 => 'bar2'}, @controller)
      e2 = Parameters.new({:foo3 => 'bar3'}, @controller)
      expected = [e1.instance_variable_get(:@params), e2.instance_variable_get(:@params)]
      result = []
      params[:bar].each do |e|
        result << e.instance_variable_get(:@params)
      end
      assert_equal expected, result
    end
    #
    # def test_permit_for_array_of_arrays
    #   object = Object.new
    #   # params = Parameters.new({'foo' => {'bar' => [[1,2,3,object],[4,5,6]]}}, @controller)
    #   params = Parameters.new({'foo' => {'bar' => [[1,2,3],[4,5,6]]}}, @controller)
    #   expected = {}
    #   assert_equal expected, params.require(:foo).permit(:bar => [])
    # end

    # def test_permit!
    #   object = Object.new
    #   params = Parameters.new({'foo' => {'bar' => [[1,2,3,object, {'a' => 'b'}],[4,5,6]]}}, @controller)
    #   expected = {:bar => [[1,2,3,object, :a => 'b'],[4,5,6]]}
    #   p params.require(:foo).permit!
    #   # assert_equal expected, params.require(:foo).permit!
    # end
    # {"foo"=>{"bar"=>[4, 5, 6, 1, {"a"=>"b"}]}}

    #permit! should work for {'foo' => {'bar' => [[1,2,3,object],[4,5,6]]}}
    private

    def setup_parameters(params)
      @controller.params = params
    end
  end
end
