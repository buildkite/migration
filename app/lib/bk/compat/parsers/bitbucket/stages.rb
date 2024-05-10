# frozen_string_literal: true

require_relative '../../pipeline/step'

module BK
  module Compat
    module BitBucketSteps
      # Implementation of stage translation
      class Stages
        def matcher(conf, *, **)
          conf.include?('stage')
        end

        def translator(conf, *, defaults: {}, **)
          stage = conf['stage']
          steps = translate_steps(stage, defaults)
          # TODO: this condition step should block all others
          condition = BK::Compat::BitBucket.translate_conditional(stage['condition'])
          BK::Compat::GroupStep.new(
            # TODO: make stage names unique
            label: stage.fetch('name', 'stage1'),
            steps: [condition, steps].flatten
          )
        end

        private

        def translate_steps(stage, defaults)
          # TODO: these steps can not have conditions
          steps = Array(stage['steps']).map { |s| recursor(s, defaults: defaults) }
          steps = BK::Compat::BitBucket.translate_trigger(stage['trigger'], steps.flatten)
          steps.pop if steps.last.is_a?(BK::Compat::WaitStep)
          steps
        end
      end
    end
  end
end
