require 'active_support/core_ext/hash/indifferent_access'
module ShieldsUp
  class Parameters
    if defined?(ActionController) && defined?(ActionController::Parameters)
      PARAM_TYPE = ActionController::Parameters
    else
      PARAM_TYPE = ActiveSupport::HashWithIndifferentAccess
    end

    PERMITTED_SCALAR_TYPES = [
        String,
        Symbol,
        NilClass,
        Numeric,
        TrueClass,
        FalseClass,
        Date,
        Time,
        # DateTimes are Dates, we document the type but avoid the redundant check.
        StringIO,
        IO,
    ]
    if defined?(ActionDispatch) && defined?(ActionDispatch::Http) && defined?(ActionDispatch::Http::UploadedFile)
      PERMITTED_SCALAR_TYPES << ActionDispatch::Http::UploadedFile
    end
    if defined?(Rack) && defined?(Rack::Test) && defined?(Rack::Test::UploadedFile)
      PERMITTED_SCALAR_TYPES << Rack::Test::UploadedFile
    end

    def with_shields_down
      saved = @controller.params
      @controller.params = @original_params
      yield
    ensure
      @controller.params = saved
    end

    def initialize(params, controller)
      raise UnsupportedParameterType.new unless params.is_a? ActiveSupport::HashWithIndifferentAccess
      @original_params = params
      @controller = controller
      @params = deep_dup_to_hash(params)
    end

    def to_s
      @params.inspect
    end

    def permit(*permissions)
      {}.tap do |permitted|
        permissions.each do |permission|
          permission, key = (permission.is_a?(Symbol) || permission.is_a?(String)) ? [permission, permission.to_s] : [permission.values.first, permission.keys.first.to_s]
          if @params.has_key?(key)
            if permission.is_a?(Symbol) || permission.is_a?(String)
                result = permit_scalar(key)
                permitted[key] = result if @params[key] == result
            else
              result = permit_nested(key, permission)
              permitted[key] = result if result
            end
          end
        end
      end.symbolize_keys
    end

    def require(key)
      self[key] or raise ParameterMissing.new("Required parameter #{key} does not exist in #{to_s}")
    end

    # def permit!
    #   deep_dup_to_hash(@params).symbolize_keys
    # end

    def [](key)
      key = key.to_s
      value = @params[key]
      if value.is_a?(Hash)
        self.class.new(@original_params[key], @controller)
      elsif value.is_a?(Array)
        [].tap do |array|
          value.each_with_index do |element, i|
            if permitted_scalar?(element)
              array << element
            elsif element.is_a? Hash
              array << self.class.new(@original_params[key][i], @controller)
            end
          end
        end
      else
        permit_scalar(key)
      end
    end

  private

    def permit_scalar(key)
      permitted_scalar?(@params[key]) ? @params[key] : nil
    end

    def permit_simple_hash(name, permissions)
      if @params[name].is_a? Hash
        self.class.new(@original_params[name], @controller).permit(*permissions)
      else
        permit_scalar(name)
      end
    end

    def permit_nested_attributes_for(name, permissions)
      {}.tap do |result|
        @params[name].each do |key, value|
          result[key] = self.class.new(@original_params[name][key], @controller).permit(*permissions) if value.is_a? Hash
          result[key] = value if permitted_scalar?(value)
        end
      end
    end

    def permit_array_of_hashes(name, permissions)
      @params[name].zip(@original_params[name]).select{|el| el[0].is_a? Hash}.collect{|el| self.class.new(el[1], @controller).permit(*permissions)}
    end

    def permit_scalars(name)
      @params[name].select { |element| permitted_scalar? element }
    end

    def integer_key?(k)
      k =~ /\A-?\d+\z/
    end

    def permit_nested(nested_name, permissions_for_nested)
      if permissions_for_nested == [] # Declaration {:comment_ids => []}.
        @params[nested_name].is_a?(Array) ? permit_scalars(nested_name) : nil
      elsif @params[nested_name].is_a? Array # Declaration {:user => :name} or {:user => [:name, :age, {:adress => ...}]}.
        permit_array_of_hashes(nested_name, permissions_for_nested)
      elsif @params[nested_name].is_a?(Hash) && @params[nested_name].keys.all? { |k| integer_key?(k) } #{ '1' => {'title' => 'First Chapter'}, '2' => {'title' => 'Second Chapter'}}
        permit_nested_attributes_for(nested_name, permissions_for_nested)
      else
        permit_simple_hash(nested_name, permissions_for_nested)
      end
    end

    def permitted_scalar?(value)
      PERMITTED_SCALAR_TYPES.any? {|type| value.is_a?(type)}
    end

    def deep_dup_to_hash(params)
      return dup_if_possible(params) unless params.is_a?(PARAM_TYPE)
      {}.tap do |dup|
        params.each do |key, value|
          dup[key] = deep_dup_to_hash(value)
        end
      end
    end

    def dup_if_possible(v)
      v.duplicable? ? v.dup : v
    end
  end
end
