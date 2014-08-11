require 'af_strong_parameters/action_controller_extensions'
require 'af_strong_parameters/forbidden_attributes_protection'

#maybe put it on FrontEndController
ActionController::Base.send(:include, AfStrongParameters::ActionControllerExtensions)
