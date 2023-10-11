# frozen_string_literal: true

module BK
  module Compat
    # GHA translation scaffolding
    class GitHubActions
      def parse_job(name, config)
        generate_base_step(name, config).tap do |bk_step|
          config['steps'].each { |step| bk_step << translate_step(step) }
          bk_step.agents.update(config.slice('runs-on'))
          bk_step.depends_on = Array(config['needs'])
          bk_step << translate_outputs(config['outputs'])
        end
      end

      def generate_base_step(name, config)
        BK::Compat::CommandStep.new(
          label: ":github: #{name}",
          key: name,
          depends_on: config.fetch('needs', []),
          env: config.fetch('env', {}),
          timeout_in_minutes: config['timeout-minutes'],
          soft_fail: config['continue-on-error']
        )
      end

      def translate_outputs(outputs)
        return nil if outputs.nil?

        bk_step = BK::Compat::CommandStep.new(
          env: { GITHUB_OUTPUT: '/tmp/outputs' },
          commands: ['source $GITHUB_OUTPUT']
        )
        outputs.keys.each do |key|
          bk_step.add_commands(
            # the original source makes variables available
            "buildkite-agent metadata set #{key} \"$#{key}\""
          )
        end

        bk_step
      end
    end
  end
end
