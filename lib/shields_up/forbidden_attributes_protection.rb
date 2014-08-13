module ShieldsUp
  class ForbiddenAttributes < RuntimeError; end

  module ForbiddenAttributesProtection
    def sanitize_for_mass_assignment(*options)
      new_attributes = options.first.keys.map(&:to_sym)
      permitted_attributes = RequestStore.store.fetch(:permitted_for_mass_assignment, {}).fetch(self.class.to_s.to_sym, [])
      if !RequestStore.exist?(:permitted_for_mass_assignment) || (new_attributes - permitted_attributes).empty?
        super
      else
        raise ShieldsUp::ForbiddenAttributes.new "#{new_attributes - permitted_attributes} not allowed to be mass-assigned on #{self.class}."
      end
    end
  end
end
