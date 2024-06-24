# frozen_string_literal: true

module BK
  module Compat
    module HarnessSteps
      # Implementation of native step translation
      class Translator
        def translate_background(name:, identifier:, **_rest)
          BK::Compat::CommandStep.new(
            label: name,
            key: identifier,
            commands: ['# Background CI stage steps should be configured as an agent-startup hook.']
          )
        end
      end
    end
  end
end
