# frozen_string_literal: true

require_relative '../../../models/steps/command'
require_relative 'strategy'

module BK
  module Compat
    module HarnessSteps
      # Implementation of native step translation
      class Translator
        def translate_run(name:, identifier:, spec:, **rest)
          base_step(name, identifier, spec, **rest)
        end

        def base_step(name, identifier, spec, strategy: {}, **)
          BK::Compat::CommandStep.new(
            label: name,
            key: identifier,
            commands: [spec['command']]
          ).tap do |cmd|
            post_keys(spec).each { |k| cmd << k }
            cmd << translate_strategy(strategy)
          end
        end

        def post_keys(spec)
          [
            translate_image(spec['image']),
            translate_shell(spec['shell'])
          ]
        end

        def translate_shell(shell)
          ["# shell is environment-dependent and should be configured in the agent'"] unless shell.nil?
        end

        def translate_image(image)
          return nil if image.nil?

          BK::Compat::Plugin.new(
            name: 'docker',
            config: {
              'image' => image
            }
          )
        end
      end
    end
  end
end
