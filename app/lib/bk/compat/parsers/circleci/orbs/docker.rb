# frozen_string_literal: true

require_relative 'docker/install_tools'
require_relative 'docker/build'
require_relative 'docker/pull_push'

module BK
  module Compat
    module CircleCISteps
      # Docker orb specific implementation
      class DockerOrb
        def matcher(orb, _conf)
          orb.start_with?('docker/')
        end

        def translator(action, config)
          method_name = "translate_#{action.tr('/-', '_')}"
          respond_to?(method_name, true) ? send(method_name, config) : unsupported_action(action)
        end

        def unsupported_action(action)
          ["# Unsupported docker orb action: #{action}"]
        end
      end
    end
  end
end
