# frozen_string_literal: true

require_relative 'caches'
require_relative 'clone'
require_relative 'image'
require_relative 'services'
require_relative 'shared'
require_relative '../../models/steps/command'
require_relative '../../models/steps/wait'

module BK
  module Compat
    module BitBucketSteps
      # Implementation of native step translation
      class Step
        def initialize(definitions: {})
          load_caches!(definitions.fetch('caches', nil))
          load_services!(definitions.fetch('services', nil))
        end

        def matcher(conf, *, **)
          conf.include?('step')
        end

        def translator(conf, *, defaults: {}, **)
          base = [base_step(defaults.merge(conf['step'])), BK::Compat::WaitStep.new]

          BK::Compat::BitBucket.translate_trigger(conf['step'].fetch('trigger', 'automatic'), base)
        end

        private

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
