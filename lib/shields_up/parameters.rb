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
                permitted[sub_hash] = @params[sub_hash].select{ |element| permitted_scalar? element }
              else
                permitted[sub_hash] = self.class.new(@params[sub_hash], @controller).permit(*permitted_for_sub_hash)
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
        self.class.new(value, @controller)
      elsif value.is_a?(Array)
        value.select{ |element| permitted_scalar?(element) }
      else
        permitted_scalar?(value) ? value : nil
      end
    end

  private

    def permitted_scalar?(value)
      PERMITTED_SCALAR_TYPES.include? value.class
    end

    def deep_dup_to_hash(params)
      {}.tap do |dup|
        params.each do |key, value|
          if [Hash, PARAM_TYPE].collect{ |klass| value.is_a?(klass) }.any?
            dup[key.to_sym] = deep_dup_to_hash(value)
          else
            dup[key.to_sym] = value.dup rescue value
          end
        end
      end
    end
  end
end
