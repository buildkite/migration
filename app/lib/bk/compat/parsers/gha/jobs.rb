# frozen_string_literal: true

require_relative 'concurrency'

module BK
  module Compat
    # GHA translation scaffolding
    class GitHubActions
      def parse_job(name, config)
        BK::Compat::CommandStep.new(
          label: ":github: #{name}",
          key: name,
          depends_on: config.fetch('needs', []),
          env: config.fetch('env', {}),
          timeout_in_minutes: config['timeout-minutes'],
          soft_fail: config['continue-on-error']
        ).tap do |bk_step|
          set_concurrency(bk_step, config) if config['concurrency']
          config['steps'].each { |step| bk_step << translate_step(step) }
          bk_step.agents.update(config.slice('runs-on'))
          bk_step.depends_on = Array(config['needs'])
        end
      end

      def parse_step(step)
        if step.include?('run')
          translate_run(step)
        elsif step.include?('uses')
          "# action #{step['usess']} can not be translated just yet"
        else
          "# step #{step} can not be translated just yet"
        end
      end

      def translate_run(step)
        BK::Compat::CommandStep.new(label: step['name']).tap do |cmd|
          cmd.add_commands('# Shell is determined in the agent') if step.include?('shell')
          cmd.add_commands('# timeouts are per-job, not step') if step.include?('timeout-minutes')
          cmd.add_commands(
            generate_command_string(
              commands: step['run'],
              env: step.fetch('env', {}),
              workdir: step['working-directory']
            )
          )
        end
      end

      def generate_command_string(commands: [], env: {}, workdir: nil)
        vars = env.map { |k, v| "#{k}='#{v}'" }
        avoid_parens = vars.empty? && workdir.nil?
        [
          avoid_parens ? nil : '(',
          workdir.nil? ? nil : "cd '#{workdir}'",
          vars.empty? ? nil : vars.join(' '),
          commands.lines(chomp: true),
          avoid_parens ? nil : ')'
        ].compact
      end
    end
  end
end
