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
          step = conf['step']
          # script is the only thing that is mandatory
          BK::Compat::CommandStep.new(
            label: step.fetch('name', 'Script step'),
            commands: step['script'],
          ).tap do |cmdstep|
            cmdstep << translate_image(step['image']) if step.include?('image')
          end
        end

        def translate_image(image)
          BK::Compat::Plugin.new(
            name: 'docker',
            config: {
              'image' => "#{image}"
            }
          )
        end
      end
    end
  end
end
