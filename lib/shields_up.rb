require 'request_store'
require 'shields_up/forbidden_attributes_protection'
require 'shields_up/action_controller_extensions'

if defined? ActionController
  if defined? ActionController::Base
    ActionController::Base.send(:include, ShieldsUp::ActionControllerExtensions)
  end
end

