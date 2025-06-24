# frozen_string_literal: true

require_relative 'docker/install_docker'
require_relative 'docker/install_docker_compose'
require_relative 'docker/install_dockerize'
require_relative 'docker/credentials'
require_relative 'docker/install_goss'
require_relative 'docker/install_docker_tools'
require_relative 'docker/build'
require_relative 'docker/pull_push'
require_relative 'docker/update_description'
require_relative 'docker/check'
require_relative 'docker/lint'

module BK
  module Compat
    module CircleCISteps
      # Docker orb specific implementation
      class DockerOrb
        def matcher?(orb, _conf)
          orb.start_with?('docker/')
        end

        def translator(action, config)
          method_name = "translate_#{action.tr('/-', '_')}"
          respond_to?(method_name) ? send(method_name, config) : unsupported_action(action)
        end

        def unsupported_action(action)
          ["# Unsupported docker orb action: #{action}"]
        end
      end
    end
  end
end
