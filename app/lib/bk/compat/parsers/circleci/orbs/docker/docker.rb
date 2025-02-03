# frozen_string_literal: true

require_relative 'commands/install_tools'
require_relative 'commands/build'
require_relative 'commands/pull_push'

module BK
  module Compat
    class Parsers
      module CircleCI
        module Orbs
          module Docker
            # Main Docker orb implementation for CircleCI translation
            class Docker
              def matcher(orb, _conf)
                orb.start_with?('docker/')
              end

              def translator(action, config)
                method_name = "translate_#{action.tr('/-', '_')}"
                respond_to?(method_name, true) ? send(method_name, config) : unsupported_action(action)
              end

              def translate_docker_install_docker(config)
                Commands.install_docker(config)
              end

              def translate_docker_build(config)
                Commands.build_docker(config)
              end

              def translate_docker_pull(config)
                Commands.pull_docker(config)
              end

              def translate_docker_push(config)
                Commands.push_docker(config)
              end

              private

              def unsupported_action(action)
                ["# Unsupported docker orb action: #{action}"]
              end
            end
          end
        end
      end
    end
  end
end
