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

    end
  end
end
