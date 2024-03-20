require_relative '../../../pipeline/step'

module BK
  module Compat
    module HarnessSteps
      # Implementation of native step translation
      class Run
        def initialize(register:)
          register.call(
            method(:matcher),
            method(:translator)
          )
        end

        private

        def matcher(type:, **)
          type == 'Run'
        end

        def translator(name:, identifier:, spec:, **rest)
          BK::Compat::CommandStep.new(
            label: name,
            key: identifier,
            commands: [ spec['command'] ]
          )
        end
      end
    end
  end
end