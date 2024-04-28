# frozen_string_literal: true

require_relative '../../pipeline/step'
require_relative '../../pipeline/plugin'

module BK
  module Compat
    module BitBucketSteps
      # Implementation of stage translation
      class Stages
        def initialize(register:)
          register.call(
            method(:matcher),
            method(:translator)
          )
        end

        private

        def matcher(conf, *, **)
          conf.include?('stages')
        end

        def translator(conf, *, defaults: {}, **)
          # TODO: these steps can not have conditions
          steps = Array(conf['steps']).map { |s| translate_step(s, defaults: defaults) }
          # TODO: this condition step should block all others
          condition = BK::Compat::BitBucket.translate_conditional(conf.fetch('condition', {}))
          BK::Compat::GroupStep.new(
            # TODO: make stage names unique
            key: conf.fetch('name', 'stage1'),
            steps: Array(condition, steps).flatten
          )
        end
      end
    end
  end
end
