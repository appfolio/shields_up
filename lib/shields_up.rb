require 'shields_up/action_controller_extensions'
require 'shields_up/forbidden_attributes_protection'

#maybe put it on FrontEndController
ActionController::Base.send(:include, ShieldsUp::ActionControllerExtensions)
