module AfStrongParameters
  class ForbiddenAttributes < RuntimeError; end

  module ForbiddenAttributesProtection
    def sanitize_for_mass_assignment(*options)
      def coming_from_controller
        caller.select{|line| line =~ /abstract_controller\/base\.rb/}.any?
      end
      new_attributes = options.first
      has_no_permit_information = !new_attributes.respond_to?(:permitted?)
      raise AfStrongParameters::ForbiddenAttributes if coming_from_controller && has_no_permit_information
      if has_no_permit_information || new_attributes.permitted?
        super
      else
        raise AfStrongParameters::ForbiddenAttributes
      end
    end
  end
end
