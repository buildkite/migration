# frozen_string_literal: true

require_relative 'expressions'

module BK
  module Compat
    # Implement GHA Builtin Steps
    class GHABuiltins
      def initialize(register:)
        register.call(
          ->(conf) { conf.include?('run') },
          method(:translate_run)
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
            workdir: step['working-directory'],
            id: step['id']
          )
        ].flatten.compact
      end

      def generate_command_string(commands: [], env: {}, workdir: nil, id: nil)
        vars = env.map { |k, v| "#{k}=\"#{v}\"" }
        cmds = commands.lines(chomp: true)
        avoid_parens = vars.empty? && workdir.nil? && (id.nil? || cmds.one?)
        [
          avoid_parens ? nil : '(',
          workdir.nil? ? nil : "cd '#{workdir}'",
          vars.empty? ? nil : vars,
          cmds,
          avoid_parens ? nil : ')',
          id.nil? ? nil : "#{BK::Compat.var_name(id, 'GHA_STEP')}=\"$$?\""
        ].compact
      end
    end


  end
end
