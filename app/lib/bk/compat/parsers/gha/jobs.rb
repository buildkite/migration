# frozen_string_literal: true

require_relative 'concurrency'
require_relative 'matrix'
require_relative 'services'
require_relative 'steps'
require_relative '../../models/steps/gha'

module BK
  module Compat
    # GHA translation scaffolding
    class GitHubActions
      def parse_job(name, config)
        bk_step = generate_base_step(name, config)
        bk_step << translate_concurrency(config['concurrency'])
        config['steps'].each { |step| bk_step << @translator.translate_step(step) }

        # these two should be last because they need to execute commands at the end
        bk_step << translate_outputs(config['outputs'], name)
        set_services(bk_step, config['services'])

        bk_step.instantiate
      end

      def generate_base_step(name, config)
        BK::Compat::GHAStep.new(
          label: ":github: #{name}",
          key: name,
          depends_on: Array(config['needs']),
          env: config.fetch('env', {}),
          timeout_in_minutes: config['timeout-minutes'],
          soft_fail: config['continue-on-error'],
          conditional: generate_if(config['if']),
          agents: config.slice('runs-on'),
          matrix: generate_matrix(config['strategy']&.fetch('matrix'))
        )
      end

      def generate_if(str)
        return nil if str.nil?

        # if is an expression but it can be missing the enclosing ${{}}
        str.strip.start_with?('${{') ? str : "${{ #{str} }}"
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
