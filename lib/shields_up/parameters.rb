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
          if permission.is_a?(Symbol)
            result = permit_scalar(permission) if @params.has_key?(permission)
            permitted[permission] = result if result.present?
          else
            sub_hash_name = permission.keys.first
            if @params.has_key?(sub_hash_name)
              permission_for_sub_hash = permission.values.first
              if permission_for_sub_hash == []
                # Declaration {:comment_ids => []}.
                result = permit_scalars(sub_hash_name)
                permitted[sub_hash_name] = result if result.present?
              else # Declaration {:user => :name} or {:user => [:name, :age, {:adress => ...}]}.
                if @params[sub_hash_name].is_a? Array
                  result = permit_array_of_hashes(sub_hash_name, permission_for_sub_hash)
                  permitted[sub_hash_name] = result if result.present?
                else
                  if @params[sub_hash_name].is_a?(Hash) && @params[sub_hash_name].keys.all? { |k| integer_key?(k) }
                    #{ '1' => {'title' => 'First Chapter'}, '2' => {'title' => 'Second Chapter'}}
                    result =  permit_nested_attributes_for(sub_hash_name, permission_for_sub_hash)
                    permitted[sub_hash_name] = result if result.present?
                  else
                    result = permit_simple_hash(sub_hash_name, permission_for_sub_hash)
                    permitted[sub_hash_name] = result
                  end
                end
              end
            end
          end
        end
      end
    end

    def require(key)
      self[key] or raise ParameterMissing.new("Required parameter #{key} does not exist in #{to_s}")
    end

    # def permit!
    #   deep_dup_to_hash(@params)
    # end

    def [](key)
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

    def permit_scalar(permission)
      permitted_scalar?(@params[permission]) ? @params[permission] : nil
    end

    def permit_simple_hash(name, permissions)
      self.class.new(@original_params[name], @controller).permit(*permissions)
    end

    def permit_nested_attributes_for(name, permissions)
      {}.tap do |result|
        @params[name].each do |key, value|
          result[key] = self.class.new(@original_params[name][key], @controller).permit(*permissions) if value.is_a? Hash
        end
      end
    end

    def permit_array_of_hashes(name, permissions)
      @params[name].zip(@original_params[name]).select{|el| el[0].is_a? Hash}.collect{|el| self.class.new(el[1], @controller).permit(*permissions)}
    end

    def permit_scalars(sub_hash)
      @params[sub_hash].select { |element| permitted_scalar? element }
    end

    def integer_key?(k)
      k =~ /\A-?\d+\z/
    end

    def permitted_scalar?(value)
      PERMITTED_SCALAR_TYPES.any? {|type| value.is_a?(type)}
    end

    def deep_dup_to_hash(params)
      {}.tap do |dup|
        params.each do |key, value|
          symbol_key = (integer_key?(key) ? key : key.to_sym)
          if value.is_a?(PARAM_TYPE)
            dup[symbol_key] = deep_dup_to_hash(value)
          elsif value.is_a? Array
            value.each do |v|
              dup[symbol_key] = [] unless dup[symbol_key].is_a? Array
              if v.is_a?(PARAM_TYPE)
                dup[symbol_key] << deep_dup_to_hash(v)
              else
                dup[symbol_key] << (v.duplicable? ? v.dup : v)
              end
            end
          else
            dup[symbol_key] = (value.duplicable? ? value.dup : value)
          end
        end
      end
    end
  end
end
