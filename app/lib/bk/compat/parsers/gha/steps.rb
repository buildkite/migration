# frozen_string_literal: true

require_relative 'expressions'

module BK
  module Compat
    # Implement GHA Builtin Steps
    class GHABuiltins
      def matcher(conf)
        conf.include?('run')
      end

      def translator(step)
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

      private

      def generate_command_string(commands: [], env: {}, workdir: nil, id: nil)
        cwd = "cd '#{workdir}'" unless workdir.nil?
        vars = env.map { |k, v| "#{k}=\"#{v}\"" }
        cmds = commands.lines(chomp: true)
        step_id = "#{BK::Compat.var_name(id, 'GHA_STEP')}=\"$$?\"" unless id.nil?

        avoid_parens = vars.empty? && workdir.nil? && (id.nil? || cmds.one?)

        ret = parens(avoid_parens, [cwd, vars, cmds]) + [step_id]

        ret.flatten.compact
      end

      def parens(skip, arr)
        skip ? arr : ['('] + arr + [')']
      end
    end

    # wrapper class to setup parameters
    class GHAStep < BK::Compat::CommandStep
      attr_accessor :transformer

      def initialize(*, **)
        super
        @transformer = method(:gha_params)
      end

      EXPRESSION_REGEXP = /\${{\s*(?<data>.*)\s*}}/
      EXPRESSION_TRANSFORMER = BK::Compat::GithubExpressions.new

      def gha_params(value)
        value.gsub(EXPRESSION_REGEXP) do |v|
          d = EXPRESSION_REGEXP.match(v)
          EXPRESSION_TRANSFORMER.transform(d[:data])
        end
      end

      def to_h
        @transformer = nil

        super
      end
    end
  end
end
