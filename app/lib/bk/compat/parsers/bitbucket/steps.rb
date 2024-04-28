# frozen_string_literal: true

require_relative '../../pipeline/step'
require_relative '../../pipeline/plugin'

require_relative 'caches'
require_relative 'image'
require_relative 'services'
require_relative 'shared'

module BK
  module Compat
    module BitBucketSteps
      # Implementation of native step translation
      class Step
        def initialize(register:, definitions: {})
          load_caches!(definitions.fetch('caches', nil))
          load_services!(definitions.fetch('services', nil))

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
          pre_keys(step).each { |k| cmd >> k }
          post_keys(step).each { |k| cmd << k }

          cmd
        end

        def pre_keys(step)
          [
            BK::Compat::BitBucket.translate_conditional(step.fetch('condition', {})),
            translate_oidc(step.fetch('oidc', false)),
            translate_services(step.fetch('services', []))
          ]
        end

        def post_keys(step)
          [
            translate_image(step.delete('image')),
            untranslatable(step),
            translate_artifacts(step.delete('artifacts')),
            translate_clone(step.fetch('clone', {})),
            translate_caches(step.fetch('caches', []))
          ]
        end

        def untranslatable(step)
          msgs = {
            'deployment' => '# `deployments` has no direct translation.',
            'fail-fast' =>
              '# `fail-fast` has no direct translation - consider using `soft_fail`/`cancel_on_build_failing`.',
            'after-script' => '# The after-script property should be configured as a pre-exit repository hook',
            'docker' => '# The availability of docker in steps depend on the agent configuration'
          }

          msgs.map do |k, message|
            message if step.include?(k)
          end.compact
        end

        def translate_artifacts(conf)
          return [] if conf.nil?

          normalized = conf.is_a?(Array) ? conf : conf['paths']

          BK::Compat::CommandStep.new(
            artifact_paths: normalized,
            commands: [
              '# IMPORTANT: artifacts are not automatically downloaded in future steps'
            ]
          )
        end

        def translate_oidc(enabled)
          return [] if enabled.nil? || !enabled

          [
            'BITBUCKET_STEP_OIDC_TOKEN="$(buildkite-agent oidc request-token)"',
            'export BITBUCKET_STEP_OIDC_TOKEN'
          ]
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
