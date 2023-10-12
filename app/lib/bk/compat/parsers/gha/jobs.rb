# frozen_string_literal: true

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
          soft_fail: config['continue-on-error'],

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

      def set_concurrency(bk_step, config)
        group, cancel_in_progress = obtain_concurrency(config['concurrency']) 
        bk_step << ["# `cancel_in_progress` is not supported. Please use Cancel Intermediate Builds."] if cancel_in_progress
        bk_step.concurrency = 1 
        bk_step.concurrency_group = group
      end

      def obtain_concurrency(concurrency)
        case concurrency
        when String
          [concurrency, nil]
        when Hash
          concurrency_arr = concurrency.to_a
          group = concurrency_arr.first.last
          cancel_in_progress = concurrency_arr.length == 2 ? concurrency_arr.last.last : nil
          [group, cancel_in_progress]
        end
      end
    end
  end
end
