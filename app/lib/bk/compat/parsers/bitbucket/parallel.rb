# frozen_string_literal: true

module BK
  module Compat
    module BitBucketSteps
      # Implementation of stage translation
      class Parallel
        def matcher(conf, *, **)
          conf.include?('parallel')
        end

        def translator(conf, *, defaults: {}, **)
          parallel = conf['parallel']
          parallel = { 'steps' => parallel } if parallel.is_a?(Array)

          # may be a good idea when/if fail-fast is properly supported
          # defaults['fail-fast'] = parallel['fail-fast']

          steps = Array(parallel['steps']).map { |s| recursor(s, defaults: defaults) }
          # by default steps will have Wait inbetween
          steps = steps.flatten.reject { |s| s.is_a?(WaitStep) }
          BK::Compat::GroupStep.new(
            # TODO: make stage names unique
            label: "parallel-#{BK::Compat::BitBucket.step_id(steps[0])}",
            steps: steps
          )
        end
      end
    end
  end
end
