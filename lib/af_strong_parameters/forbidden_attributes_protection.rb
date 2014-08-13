module AfStrongParameters
  class ForbiddenAttributes < RuntimeError; end

  module ForbiddenAttributesProtection
    def sanitize_for_mass_assignment(*options)
      new_attributes = options.first.keys.map(&:to_sym)
      permitted_attributes = Thread.current.thread_variable_get(:permitted_for_mass_assignment).try(:fetch, self.class.to_s.underscore.to_sym) || []
      if !Thread.current.thread_variable?(:permitted_for_mass_assignment) || (new_attributes - permitted_attributes).empty?
        super
      else
        raise AfStrongParameters::ForbiddenAttributes "#{new_attributes - permitted_attributes} not allowed to be mass-assigned on #{self.class}."
      end
    end
  end
end
