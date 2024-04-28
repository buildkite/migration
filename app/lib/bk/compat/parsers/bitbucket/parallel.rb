# frozen_string_literal: true

require_relative '../../pipeline/step'

module BK
  module Compat
    module BitBucketSteps
      # Implementation of stage translation
      class Parallel
        def initialize(register:, recursor: nil)
          @recursor = recursor # to call back to translate steps further
          register.call(
            method(:matcher),
            method(:translator)
          )
        end

        private

        def matcher(conf, *, **)
          conf.include?('parallel')
        end

        def translator(conf, *, defaults: {}, **)
          stage = conf['parallel']

          defaults['fail-fast'] = stage['fail-fast']

          steps = Array(stage['steps']).map { |s| @recursor&.call(s, defaults: defaults) }
          BK::Compat::GroupStep.new(
            # TODO: make stage names unique
            label: stage.fetch('name', 'parallel'),
            steps: [condition, steps].flatten
          )
        end
      end
    end
  end
end
