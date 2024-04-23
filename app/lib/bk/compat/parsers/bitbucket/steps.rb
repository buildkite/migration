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
            commands: step['script']
          ).tap do |cmd|
            cmd.agents[:size] = step['size'] if step.include?('size')
            # Array call is to force a single-value string still works
            Array(step.fetch('runs-on', nil)).each { |tag| cmd.agents[tag] = '*' }
            cmd.timeout_in_minutes = step.fetch('max-time', nil)
            # Specify image if it was defined on the step
            cmd << translate_image(step['image']) if step.include?('image')
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
