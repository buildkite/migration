# frozen_string_literal: true

require_relative 'concurrency'
require_relative 'matrix'
require_relative 'branches'
require_relative 'steps'

module BK
  module Compat
    # GHA translation scaffolding
    class GitHubActions
      def parse_job(name, config)
        bk_step = generate_base_step(name, config)
        set_concurrency(bk_step, config) if config['concurrency']
        set_matrix(bk_step, config) if config['strategy']
        set_branch_filters(bk_step, config) if config['workflow_triggers']
        config['steps'].each { |step| bk_step << translate_step(step) }
        bk_step.agents.update(config.slice('runs-on'))
        bk_step.depends_on = Array(config['needs'])
        bk_step << translate_outputs(config['outputs'], name)
        bk_step.instantiate
      end

      def generate_base_step(name, config)
        BK::Compat::GHAStep.new(
          label: ":github: #{name}",
          key: name,
          depends_on: config.fetch('needs', []),
          env: config.fetch('env', {}),
          timeout_in_minutes: config['timeout-minutes'],
          soft_fail: config['continue-on-error']
        )
      end

      def translate_outputs(outputs, job_name)
        return nil if outputs.nil?

        bk_step = BK::Compat::GHAStep.new(
          env: { GITHUB_OUTPUT: '/tmp/outputs' },
          commands: ['source $GITHUB_OUTPUT']
        )
        outputs.each_key do |key|
          bk_step.add_commands(
            # the original source makes variables available
            "buildkite-agent metadata set \"#{job_name}.#{key}\" \"$#{key}\""
          )
        end

        bk_step
      end
    end
  end
end
