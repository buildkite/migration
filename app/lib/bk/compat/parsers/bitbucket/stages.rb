# frozen_string_literal: true

require_relative '../../pipeline/step'

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
          # TODO: these steps can not have conditions
          steps = Array(stage['steps']).map { |s| @recursor&.call(s, defaults: defaults) }
          # TODO: this condition step should block all others
          condition = BK::Compat::BitBucket.translate_conditional(stage['condition'])
          steps = BK::Compat::BitBucket.translate_trigger(stage['trigger'], steps.flatten)
          steps.pop if steps.last.is_a?(BK::Compat::WaitStep)
          BK::Compat::GroupStep.new(
            # TODO: make stage names unique
            label: stage.fetch('name', 'stage1'),
            steps: [condition, steps].flatten
          )
        end
      end
    end
  end
end
