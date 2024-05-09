# frozen_string_literal: true

module BK
  module Compat
    module BitBucketSteps
      # Implementation of native step translation
      class Import
        def initialize(register:)
          register.call(
            method(:matcher),
            method(:translator)
          )
        end

        private

        def matcher(conf, *, **)
          conf.include?('import')
        end

        def translator(conf, *, **)
          BK::Compat::CommandStep.new(
            label: 'import step',
            commands: ["# Import steps not supported yet #{conf}"]
          )
        end
      end
    end
  end
end
