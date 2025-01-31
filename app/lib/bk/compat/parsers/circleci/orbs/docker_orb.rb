# frozen_string_literal: true

require_relative 'docker/install_tools'
require_relative 'docker/build'
require_relative 'docker/pull_push'
# require_relative 'orbs/docker/lint'
# require_relative 'update'
# require_relative 'check'

module BK
  module Compat
    module CircleCISteps
      # Docker orb specific implementation
      class DockerOrb
        def initialize
          @install_tools = DockerInstallTools.new
          @build = DockerBuild.new
          @push_pull = DockerPushPull.new
        end

        def matcher(orb, _conf)
          orb.start_with?('docker/')
        end

        def translator(action, config)
          method_name = "translate_#{action.tr('/-', '_')}"
          respond_to?(method_name, true) ? send(method_name, config) : unsupported_action(action)
        end

        def translate_docker_install_docker(config)
          @install_tools.translate_docker_install_docker(config)
        end

        def translate_docker_build(config)
          @build.translate_docker_build(config)
        end

        def translate_docker_pull(config)
          @push_pull.translate_docker_pull(config)
        end

        def translate_docker_push(config)
          @push_pull.translate_docker_push(config)
        end

        def unsupported_action(action)
          ["# Unsupported docker orb action: #{action}"]
        end
      end
    end
  end
end
