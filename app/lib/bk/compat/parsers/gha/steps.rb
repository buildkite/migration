# frozen_string_literal: true

module BK
  module Compat
    # Implement GHA Builtin Steps
    class GHABuiltins
      def initialize(register:)
        register.call(
          ->(conf) { conf.include?('run') },
          method(:translate_run)
        )

        register.call(
          ->(conf) { conf.include?('uses') },
          method(:translate_uses)
        )
      end

      private

      def translate_run(step)
        [
          step.include?('name') ? "echo '~~~ #{step['name']}'" : nil,
          step.include?('shell') ? '# Shell is determined in the agent' : nil,
          step.include?('timeout-minutes') ? '# timeouts are per-job, not step' : nil,
          generate_command_string(
            commands: step['run'],
            env: step.fetch('env', {}),
            workdir: step['working-directory']
          )
        ].flatten.compact
      end

      def translate_uses(step)
        "# action #{step['uses']} can not be translated just yet"
      end

      def generate_command_string(commands: [], env: {}, workdir: nil)
        vars = env.map { |k, v| "#{k}=\"#{v}\"" }
        avoid_parens = vars.empty? && workdir.nil?
        [
          avoid_parens ? nil : '(',
          workdir.nil? ? nil : "cd '#{workdir}'",
          vars.empty? ? nil : vars,
          commands.lines(chomp: true),
          avoid_parens ? nil : ')'
        ].compact
      end
    end
  end
end
