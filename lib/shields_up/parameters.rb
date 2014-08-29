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
      @original_params = params
      @controller = controller
      @params = deep_dup_to_hash(params || {})
    end

    def to_s
      @params.inspect
    end

    def permit(*permissions)
      {}.tap do |permitted|
        permissions.each do |permission|
          if permission.is_a?(Symbol)
            permitted[permission] = @params[permission] if @params.has_key?(permission) && permitted_scalar?(@params[permission])
          else
            sub_hash = permission.keys.first
            if @params.has_key?(sub_hash)
              permitted_for_sub_hash = permission.values.first
              if permitted_for_sub_hash == []
                # Declaration {:comment_ids => []}.
                permitted[sub_hash] = @params[sub_hash].select{ |element| permitted_scalar? element }
              else # Declaration {:user => :name} or {:user => [:name, :age, {:adress => ...}]}.
                if @params[sub_hash].is_a? Array
                  @params[sub_hash].each do |element|
                    if element.is_a? Hash
                      permitted[sub_hash] ||= []
                      permitted[sub_hash] << self.class.new(element, @controller).permit(*permitted_for_sub_hash)
                    end
                  end
                else
                  if @params[sub_hash].is_a?(Hash) && @params[sub_hash].keys.all? { |k| k =~ /\A-?\d+\z/ }
                    #{ '1' => {'title' => 'First Chapter'}, '2' => {'title' => 'Second Chapter'}}
                    @params[sub_hash].each do |key,value|
                      if value.is_a? Hash
                        permitted[sub_hash] ||= {}
                        permitted[sub_hash][key] = self.class.new(value, @controller).permit(*permitted_for_sub_hash)
                      end
                    end
                  else
                    permitted[sub_hash] = self.class.new(@params[sub_hash], @controller).permit(*permitted_for_sub_hash)
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

    def permit!
      deep_dup_to_hash(@params)
    end

    def [](key)
      value = @params[key]
      if value.is_a?(Hash)
        self.class.new(value, @controller)
      elsif value.is_a?(Array)
        array = []
        value.each do |element|
          if permitted_scalar?(element)
            array << element
          elsif element.is_a? Hash
            array << self.class.new(element, @controller)
          end
        end
        array
      else
        permitted_scalar?(value) ? value : nil
      end
    end

    def ==(params)
      @original_params = params.instance_variable_get(:@original_params) && @controller = params.instance_variable_get(:@controller)  && @params = params.instance_variable_get(:@params)
    end

  private

    def permitted_scalar?(value)
      PERMITTED_SCALAR_TYPES.any? {|type| value.is_a?(type)}
    end

    def deep_dup_to_hash(params)
      {}.tap do |dup|
        params.each do |key, value|
          symbol_key = key =~ /\A-?\d+\z/ ? key : key.to_sym
          if [Hash, PARAM_TYPE].collect{ |klass| value.is_a?(klass) }.any?
            dup[symbol_key] = deep_dup_to_hash(value)
          elsif value.is_a? Array
            value.each do |v|
              dup[symbol_key] = [] unless dup[symbol_key].is_a? Array
              if [Hash, PARAM_TYPE].collect{ |klass| v.is_a?(klass) }.any?
                dup[symbol_key] << deep_dup_to_hash(v)
              else
                if v.duplicable?
                  dup[symbol_key] << v.dup
                else
                  dup[symbol_key] << v
                end
              end
            end
          else
            dup[symbol_key] = value.dup rescue value
            #???? why do we need to dup, what if some thing can not be duped say fixnum
          end
        end
      end
    end
  end
end
