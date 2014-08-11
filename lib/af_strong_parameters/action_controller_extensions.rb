module AfStrongParameters
  module ActionControllerExtensions
    before_filter :initialize_af_strong_parameters

    def permit_for_model(model, attributes)
      white_list = attributes.is_a?(Array) ? attributes : [attributes]
      key = model_symbol(model)
      old_white_list = permitted[key] || []
      permitted[key] = (white_list.map(&:to_sym) + old_white_list).compact
    end

    def permitted_for_model(model)
      permitted[model_symbol(model)] || []
    end

    def permitted
      Thread.current.thread_variable_get(:permitted_for_mass_assignment)
    end

  private

    def initialize_af_strong_parameters
      self.permitted = {}
    end

    def permitted=(arg)
      Thread.current.thread_variable_set(:permitted_for_mass_assignment, arg)
    end

    def model_symbol(model)
      model.name.underscore.to_sym
    end
  end
end

