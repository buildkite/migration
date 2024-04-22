# frozen_string_literal: true

require_relative '../../pipeline/step'

module BK
  module Compat
    module BitBucketSteps
      # Implementation of native step translation
      class Step
        def initialize(register:)
          register.call(
            method(:matcher),
            method(:translator)
          )
        end

        private

        def matcher(conf, *, **)
          conf.include?('step')
        end

        def translator(conf, *, **)
          BK::Compat::CommandStep.new(
            label: 'step',
            key: 'step',
            commands: [ "Step with #{conf['step']}" ]
          )
        end
      end
    end
  end
end
