# frozen_string_literal: true

module BK
  module Compat
    module BitBucketSteps
      # Implementation of stage translation
      class Stages
        def initialize(register:, recursor: nil)
          @recursor = recursor # to call back to translate steps further
          register.call(
            method(:matcher),
            method(:translator)
          )
        end

        private

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

        def translate_steps(stage, defaults)
          # TODO: these steps can not have conditions
          steps = Array(stage['steps']).map { |s| @recursor&.call(s, defaults: defaults) }
          steps = BK::Compat::BitBucket.translate_trigger(stage['trigger'], steps.flatten)
          steps.pop if steps.last.is_a?(BK::Compat::WaitStep)
          steps
        end
      end
    end
  end
end
