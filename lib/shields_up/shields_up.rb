module ShieldsUp
  def self.included(klass)
    klass.before_filter do
      unless params.is_a?(ShieldsUp::Parameters)
        params.permit! if params.respond_to?(:permit!)
        self.params = ShieldsUp::Parameters.new(params, self)
      end
    end
    klass.rescue_from(ShieldsUp::ParameterMissing) do |parameter_missing_exception|
      render :text => "Required parameter missing: #{parameter_missing_exception}", :status => :bad_request
    end
  end
end
