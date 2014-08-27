module ShieldsUp
  def self.included(klass)
    klass.before_filter do
      self.params = ShieldsUp::Parameters.new(params, self) unless params.is_a?(ShieldsUp::Parameters)
    end
    klass.rescue_from(ShieldsUp::ParameterMissing) do |parameter_missing_exception|
      render :text => "Required parameter missing: #{parameter_missing_exception}", :status => :bad_request
    end
  end
end
