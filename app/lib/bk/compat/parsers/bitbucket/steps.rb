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
          base = base_step(conf['step'])

          if conf['step'].fetch('trigger', 'automatic') == 'manual'
            # TODO: ensure this is a valid, deterministic and unique key
            k = base.key || base.label || 'cmd'

            input = BK::Compat::InputStep.new(key: "execute-#{k}", prompt: "Execute step #{k}?")
            base.depends_on = [input.key]
            [input, base]
          else
            base
          end
        end

        def base_step(step)
          BK::Compat::CommandStep.new(
            label: step.fetch('name', 'Script step'),
            commands: translate_scripts(Array(step['script'])),
            agents: translate_agents(step.slice('size', 'runs-on'))
          ).tap do |cmd|
            cmd.timeout_in_minutes = step.fetch('max-time', nil)
            # Specify image if it was defined on the step
            cmd << translate_image(step['image']) if step.include?('image')
            # Translate after-script
            cmd.add_commands('# The after-script property should be configured as a pre-exit repository hook') if !step['after-script'].nil?
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
        
        def translate_agents(conf)
          {}.tap do |h|
            h[:size] = conf['size'] if conf.include?('size')
            # Array call is to force a single-value string still works
            Array(conf.fetch('runs-on', nil)).each { |tag| h[tag] = '*' }
          end
        end

        def translate_scripts(scripts)
          scripts.map do |s|
            case s
            when String
              s
            when Hash
              # assume it is a pipe
              "# Pipe #{s['pipe']} is not currently supported, maybe a plugin?"
            else
              "# Invalid script element #{s}"
            end
          end
        end
      end
    end
  end
end
