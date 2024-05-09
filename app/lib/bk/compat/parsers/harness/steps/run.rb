# frozen_string_literal: true

require_relative '../../../pipeline/step'

module BK
  module Compat
    module HarnessSteps
      # Implementation of native step translation
      class Translator
        def translate_run(name:, identifier:, spec:, **_rest)
          BK::Compat::CommandStep.new(
            label: name,
            key: identifier,
            commands: [spec['command']]
          )
        end
      end
    end
  end
end
