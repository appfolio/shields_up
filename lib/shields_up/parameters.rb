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

    def without_mass_assignment_protection
      saved = @controller.params
      @controller.params = @original_params
      yield
    ensure
      @controller.params = saved
    end

    def initialize(params, controller)
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
            raise ParameterIsArray.new("#{permission} is an array parameter but only a scalar was permitted.\nUse [#{permission}] instead of #{permission} if you want to allow an array.") if @params[permission].is_a?(Array)
            permitted[permission] = @params[permission] if @params.has_key?(permission) && permitted_scalar?(@params[permission])
          else
            sub_hash = permission.keys.first
            permitted_for_sub_hash = permission.values.first
            if sub_hash.is_a?(Array)
              sub_hash = sub_hash.first
              permitted[sub_hash] = to_permitted_scalar_array(@params[sub_hash].collect{ |entry| self.class.new(entry, @controller).permit(*permitted_for_sub_hash) }) if @params.has_key?(sub_hash)
            else
              permitted[sub_hash] = self.class.new(@params[sub_hash], @controller).permit(*permitted_for_sub_hash) if @params.has_key?(sub_hash)
            end
          end
        end
      end
    end

    def require(key)
      if @params.has_key?(key)
        if @params[key].is_a?(Array)
          to_permitted_scalar_array(@params[key].collect{ |entry| self.class.new(entry, @controller) })
        else
          self.class.new(@params[key], @controller)
        end
      else
        raise ParameterMissing.new("Required parameter #{key} does not exist in #{to_s}")
      end
    end

    # def permit!
    #   deep_dup_to_hash(@params)
    # end

    def [](key)
      value = @params[key]
      if value.is_a?(Hash)
        self.class.new(value, @controller)
      else
        permitted_scalar?(value) ? value : nil
      end
    end

  private

    def permitted_scalar?(value)
      PERMITTED_SCALAR_TYPES.include? value.class
    end

    def to_permitted_scalar_array(array)
      array.select{ |entry| permitted_scalar?(entry) }
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
