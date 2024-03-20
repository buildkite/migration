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

        def translator(**step)
          BK::Compat::CommandStep.new(commands: [ "Run step with config #{step}" ])
        end
      end
    end
  end
end