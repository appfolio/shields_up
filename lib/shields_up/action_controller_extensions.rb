module ShieldsUp
  module ActionControllerExtensions
    def self.included(klass)
      klass.before_filter do
        self.permitted = {} unless permitted
      end
    end

    def permit_for_model(model, attributes)
      white_list = attributes.is_a?(Array) ? attributes : [attributes]
      key = model_symbol(model)
      old_white_list = permitted[key] || []
      permitted[key] = (white_list.map(&:to_sym) + old_white_list).uniq
    end

    def permitted_for_model(model)
      permitted[model_symbol(model)] || []
    end

    def permitted
      RequestStore.store[:permitted_for_mass_assignment]
    end

  private

    def permitted=(arg)
      RequestStore.store[:permitted_for_mass_assignment] = arg
    end

    def model_symbol(model)
      model.to_s.to_sym
    end
  end
end

