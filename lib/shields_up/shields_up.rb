module ShieldsUp
  def self.included(klass)
    klass.before_filter do
      self.params = ShieldsUp::Parameters.new(params) unless params.is_a?(ShieldsUp::Parameters)
    end
  end

  class Parameters
    def initialize(params)
      @params = deep_dup_to_hash(params)
    end

    def to_s
      @params.inspect
    end

    def permit(*permissions)
      {}.tap do |permitted|
        permissions.each do |permission|
          if permission.is_a?(Symbol) && @params.has_key?(permission)
            raise "Use [#{permission}] instead of #{permission} if you want to allow an array" if @params[permission].is_a?(Array)
            permitted[permission] = @params[permission]
          else
            sub_hash = permission.keys.first
            permitted_for_sub_hash = permission.values.first
            if sub_hash.is_a?(Array)
              sub_hash = sub_hash.first
              permitted[sub_hash] = @params[sub_hash].collect{ |entry| self.class.new(entry).permit(*permitted_for_sub_hash) } if @params.has_key?(sub_hash)
            else
              permitted[sub_hash] = self.class.new(@params[sub_hash]).permit(*permitted_for_sub_hash) if @params.has_key?(sub_hash)
            end
          end
        end
      end
    end

    def require(key)
      if @params.has_key?(key)
        if @params[key].is_a?(Array)
          @params[key].collect{ |entry| self.class.new(entry) }
        else
          self.class.new(@params[key])
        end
      else
        raise RuntimeError
      end
    end

    def permit!
      deep_dup_to_hash(@params)
    end

    def [](key)
      value = @params[key]
      value.is_a?(Hash) ? self.class.new(value) : value
    end

  private

    def deep_dup_to_hash(params)
      {}.tap do |dup|
        params.each do |key, value|
          if [Hash, ActionController::Parameters].collect{ |klass| value.is_a?(klass) }.any?
            dup[key.to_sym] = deep_dup_to_hash(value)
          else
            dup[key.to_sym] = value.dup rescue value
          end
        end
      end
    end
  end
end
