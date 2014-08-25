module ShieldsUp
  def self.included(klass)
    klass.before_filter do
      self.params = ShieldsUp::Parameters.new(params, self) unless params.is_a?(ShieldsUp::Parameters)
    end
  end
end
