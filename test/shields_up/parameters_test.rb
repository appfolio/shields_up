require 'helper'

module ShieldsUp

  class Parameters
    def ==(params)
      @original_params == params.instance_variable_get(:@original_params) && @controller == params.instance_variable_get(:@controller)  && @params == params.instance_variable_get(:@params)
    end
  end

  class ParametersTest < MiniTest::Unit::TestCase
    class Controller
      attr_accessor :params
    end

    def setup
      super
      @controller = Controller.new
    end

    def test_access
      params = Parameters.new(as_params({'a' => ['b', 'c', 1],'foo' => 'bar', 'hashes' => {'can' => {'be' => 'nested'}}}), @controller)
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
      params = Parameters.new(as_params({'foo' => object}), @controller)
      expected = {}
      assert_equal expected, params.permit(:foo)
    end

    def test_permit_array
      object = Controller.new
      params = Parameters.new(as_params({'foo' => ['1', '2', '3', 1, object]}), @controller)
      expected = {:foo => ['1', '2', '3', 1]}
      assert_equal expected, params.permit(:foo => [])
      expected = {}
      assert_equal expected, params.permit(:foo)
    end

    def test_permit_legal_array
      params = Parameters.new(as_params({'foo' => ['1', '2', '3', 1]}), @controller)
      expected = {:foo => ['1', '2', '3', 1]}
      assert_equal expected, params.permit(:foo => [])
      expected = {}
      assert_equal expected, params.permit(:foo)
    end

    def test_permit_hash
      params = Parameters.new(as_params({'foo' => 'bar'}), @controller)
      expected = {:foo => 'bar'}
      assert_equal expected, params.permit(:foo)
    end

    def test_permit_hash_nested
      params = Parameters.new(as_params({'foo' => {'bar' => {'name' => 'pirats', 'number' => '5', 'secret' => '1337'}}}), @controller)
      expected = {:foo => {:bar => {:name => 'pirats', :number => '5'}}}
      assert_equal expected, params.permit(:foo => [:bar => [:name, :number]])
    end

    def test_require
      params = Parameters.new(as_params({'foo' => 'bar'}), @controller)
      expected = 'bar'
      assert_equal expected, params.require(:foo)
    end

    def test_require_uses_internal_access
      params = Parameters.new(as_params({'foo' => 'bar'}), @controller)
      params.expects(:[]).with(:foo).returns('bar')
      expected = 'bar'
      assert_equal expected, params.require(:foo)
    end

    def test_require_nested
      params = Parameters.new(as_params({'foo' => {'bar' => 'baz'}}), @controller)
      expected = 'baz'
      assert_equal expected, params.require(:foo).require(:bar)
    end

    def test_require_raises
      params = Parameters.new(as_params({}), @controller)
      assert_raises ParameterMissing do
        params.require(:foo)
      end
    end

    def test_with_shields_down
      object = Controller.new
      setup_parameters(Parameters.new(as_params(ActiveSupport::HashWithIndifferentAccess.new('param' => object)), @controller))
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
      params = Parameters.new(as_params({'bar' => [{'foo2' => 2}, {'foo3' => 'bar3'}]}), @controller)
      expected = {:bar=>[{:foo2=>2}, {}]}
      assert_equal expected, params.permit(:bar => [:foo2])
    end

    def test_get_for_array_of_hashes
      params = Parameters.new(as_params({'bar' => [{'foo2' => 'bar2'}, {'foo3' => 'bar3'}]}), @controller)
      expected = [Parameters.new(as_params({'foo2' => 'bar2'}), @controller), Parameters.new(as_params({'foo3' => 'bar3'}), @controller)]
      actual = params[:bar]
      assert_equal expected, actual
    end

    # def test_permit!
    #   object = Object.new
    #   params = Parameters.new(as_params({'foo' => {'bar' => [[1,2,3,object, {'a' => 'b'}],[4,5,6]]}}), @controller)
    #   expected = {:bar => [[1,2,3,object, 'a' => 'b'],[4,5,6]]}
    #   assert_equal expected, params.require(:foo).permit!
    # end

    def test_permit_array_of_records_using_numeric_hash_keys
      raw_parameter = as_params({'title' => 'Some Book',
                                 'chapters_attributes' => { '1' => {'title' => 'First Chapter'},
                                                            '2' => {'title' => 'Second Chapter'}}})
      params = Parameters.new(raw_parameter, @controller)
      expected = {:title => 'Some Book',
                  :chapters_attributes => { '1' => {:title => 'First Chapter'},
                                            '2' => {:title => 'Second Chapter'}}}
      assert_equal expected, params.permit(:title, chapters_attributes: [:title])
    end

    def test_get_array_of_records_using_numeric_hash_keys
      raw_parameter = as_params({'title' => 'Some Book',
                                 'chapters_attributes' => { '1' => {'title' => 'First Chapter'},
                                                            '2' => {'title' => 'Second Chapter'}}})
      params = Parameters.new(raw_parameter, @controller)
      expected = Parameters.new(as_params({'1' => {'title' => 'First Chapter'}, '2' => {'title' => 'Second Chapter'}}), @controller)
      assert_equal expected, params[:chapters_attributes]
    end

    def test_strong_parameter_similarity
      raw_parameter = as_params({'titles' => []})
      params = Parameters.new(raw_parameter, @controller)
      expected = {}
      actual = params.permit(:a)
      assert_equal expected, actual

      raw_parameter = as_params({'titles' => []})
      params = Parameters.new(raw_parameter, @controller)
      expected = {:titles => []}
      actual = params.permit(:titles => [])
      assert_equal expected, actual

      raw_parameter = as_params({'titles' => [{'c' => 1}, {'c' => 2}]})
      params = Parameters.new(raw_parameter, @controller)
      expected = {:titles => [{}, {}]}
      actual = params.permit(:titles => [:x])
      assert_equal expected, actual

      raw_parameter = as_params({'titles' => []})
      params = Parameters.new(raw_parameter, @controller)
      expected = {:titles => []}
      actual = params.permit(:titles => [:x])
      assert_equal expected, actual


      raw_parameters = as_params({'b' => {'1' => {'a' => 1}, '2' => {'a' => 2}}})
      parameters = Parameters.new(raw_parameters, @controller)
      expected = {:b=>{'1'=>{:a=>1}, '2'=>{:a=>2}}}
      actual = parameters.permit(:b => [:a])
      assert_equal expected, actual

      raw_parameters = as_params({'b' => {'1' => {'a' => 1}, '2' => {'a' => 2}}})
      parameters = Parameters.new(raw_parameters, @controller)
      expected = {:b=>{"1"=>{}, "2"=>{}}}
      actual = parameters.permit(:b => [:c])
      assert_equal expected, actual
    end

    private

    def setup_parameters(params)
      @controller.params = params
    end

    def as_params(hash)
      ActiveSupport::HashWithIndifferentAccess.new(hash)
    end

  end
end
