# frozen_string_literal: true

require_relative '../../../models/steps/command'
require_relative '../../../models/plugin'

module BK
  module Compat
    module HarnessSteps
      # Implementation of native step translation
      class Translator
        private

        def translate_background(name:, identifier:, spec:, **_rest)
          conf = spec.slice('image', 'command', 'entrypoint', 'privileged')
          conf['environment'] = spec.delete('envVariables')
          conf['ports'] = spec.delete('portBindings')
          conf['user'] = spec.delete('runAsUser')
          compose_conf = { 'services' => { identifier => conf.compact } }

          cmds = [
            '# to make background services work, add the following composefile to your repository',
            spec.include?('shell') ? '# configure their command to force a particular shell in services' : nil,
            "cat > compose.yaml << EOF\n#{compose_conf.to_yaml}\nEOF"
          ]

          BK::Compat::CommandStep.new(
            key: "background-#{name}",
            commands: cmds.compact,
            plugins: [
              BK::Compat::Plugin.new(
                name: 'docker-compose',
                config: {
                  run: 'app'
                }
              )
            ]
          )
        end
      end
    end
  end
end
