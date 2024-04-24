# frozen_string_literal: true

require_relative '../../pipeline/step'
require_relative '../../pipeline/plugin'

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

        def translator(conf, *, defaults: {}, **)
          base = base_step(defaults.merge(conf['step']))

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
          cmd = BK::Compat::CommandStep.new(
            label: step.fetch('name', 'Script step'),
            commands: translate_scripts(Array(step['script'])),
            agents: translate_agents(step.slice('size', 'runs-on')),
            timeout_in_minutes: step.delete('max-time')
          )

          other_keys(step).each { |k| cmd << k }
          cmd
        end

        def other_keys(step)
          [
            translate_image(step.delete('image')),
            untranslatable(step),
            translate_clone(step.fetch('clone', {}))
          ]
        end

        def untranslatable(step)
          msgs = {
            'deployment' => '# `deployments` has no direct translation.',
            'fail-fast' =>
              '# `fail-fast` has no direct translation - consider using `soft_fail`/`cancel_on_build_failing`.',
            'after-script' => '# The after-script property should be configured as a pre-exit repository hook'
          }

          msgs.map do |k, message|
            message if step.include?(k)
          end.compact
        end

        def translate_clone(opts)
          sparse_checkout = opts.delete('sparse-checkout')
          enabled = opts.delete('enabled')
          msg = '# repository interactions (clone options) should be configured in the agent itself'

          # nothing specified
          return [] if sparse_checkout.nil? && enabled.nil? && opts.empty?

          BK::Compat::CommandStep.new(commands: msg).tap do |cmd|
            cmd.env['BUILKITE_REPO'] = '' unless enabled.nil? || enabled
            cmd << sparse_checkout_plugin(sparse_checkout)
          end
        end

        def sparse_checkout_plugin(conf)
          return [] if conf.nil? || !conf.fetch('enabled', true)

          BK::Compat::Plugin.new(
            name: 'sparse-checkout',
            config: {
              'paths' => conf['patterns'],
              'no-cone' => !conf.fetch('cone-mode', true)
            }
          )
        end

        def translate_image(image)
          return [] if image.nil?

          BK::Compat::Plugin.new(
            name: 'docker',
            config: {
              'image' => image.to_s
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
