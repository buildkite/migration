# frozen_string_literal: true

require 'parslet'

module BK
  module Compat
    # parse GHA expressions
    # https://docs.github.com/en/actions/learn-github-actions/expressions
    class ExpressionParser < Parslet::Parser
      # helper rules
      rule(:space) { match('\s').repeat(1) }
      rule(:space?) { space.maybe }
      rule(:quote) { match('\'') }

      rule(:base_exp) { space? >> (parens | unary_op | functions | literals) >> space? }
      # TODO: allow operations to include other operations
      rule(:expression) { operations | base_exp }

      rule(:literals) { boolean.as(:bool) | null.as(:null) | number.as(:num) | string | context }
      rule(:boolean) { str('false') | str('true') }
      rule(:null) { str('null') }

      rule(:number) { hex | exp | float | signed_integer }
      rule(:integer) { match('[0-9]').repeat(1) }
      rule(:signed_integer) { str('-').maybe >> integer }
      rule(:float) { signed_integer >> str('.') >> integer }
      rule(:hex) { str('0x') >> match('[0-9a-f]').repeat(1) }
      rule(:exp) { float >> match('[eE]') >> signed_integer }

      # Docs state that strings must be quoted (unless they are not surrounded with ${{ }})
      rule(:string) { quote >> (unquoted_string >> (str("''") >> unquoted_string).repeat).as(:str) >> quote }
      rule(:unquoted_string) { match('[^\']').repeat }

      rule(:parens) { (str('(') >> expression >> str(')')).as(:paren) }

      rule(:operations) do
        infix_expression(
          base_exp,
          [str('<='), 1],
          [str('<'), 1],
          [str('>='), 1],
          [str('>'), 1],
          [str('=='), 2],
          [str('!='), 2],
          [str('&&'), 1],
          [str('||'), 1]
        )
      end
      rule(:unary_op) { (str('!') >> expression).as(:not) } # can not name it "not"

      rule(:functions) { arg_functions | status_functions }

      rule(:arg_functions) { func_name.as(:func) >> str('(') >> arguments.repeat(0, 1).as(:args) >> str(')') }
      rule(:arguments) { expression >> (str(',') >> expression).repeat }
      rule(:func_name) do
        str('contains') |
          str('startsWith') |
          str('endsWith') |
          str('format') |
          str('join') |
          str('toJSON') |
          str('fromJSON') |
          str('hashFiles')
      end
      rule(:status_functions) { status_func.as(:status) >> str('(') >> space? >> str(')') }
      rule(:status_func) do
        str('success') |
          str('always') |
          str('cancelled') |
          str('failure')
      end

      rule(:context) { (ctx_name >> (str('.') >> atom).repeat(1)).as(:context) }
      rule(:ctx_name) do
        str('env') |
          str('github') |
          str('inputs') |
          str('jobs') |
          str('job') |
          str('matrix') |
          str('needs') |
          str('runner') |
          str('secrets') |
          str('steps') |
          str('strategy') |
          str('vars')
      end
      rule(:atom) { str('*') | (match('[_a-zA-Z]') >> match('[a-zA-Z0-9_-]').repeat) }

      root(:expression)
    end

    # Transform a GHA expression to something that BuildKite can probably understand
    class ExpressionTransform < Parslet::Transform
      rule(bool: simple(:b)) { b.to_s }
      rule(num: simple(:n)) { n.to_i }
      rule(str: simple(:s)) { s.to_s }
      rule(:null) { 0 }

      rule(paren: simple(:e)) { "(#{e})" }
      rule(not: simple(:t)) { "!#{t}" }

      rule(l: simple(:lhs), o: simple(:o), r: simple(:rhs)) { "#{lhs} #{o} #{rhs}" }
      rule(status: simple(:s)) { "#{s} not currently supported" }

      rule(func: simple(:func), args: subtree(:args)) do
        case func
        when 'contains'
          "#{args[0]} ~= /#{args[1]}/"
        when 'startsWith'
          "#{args[0]} ~= /^#{args[1]}/"
        when 'endsWith'
          "#{args[0]} ~= /#{args[1]}$/"
        else
          "#{func} not currently supported with #{args}"
        end
      end

      rule(context: simple(:c)) { GithubContext.replace(c.to_s) }
    end

    class GithubContext
      def self.replace(str)
        context, rest = str.split('.', 2)
        send("replace_context_#{context}", rest)
      rescue NoMethodError
        "Context element #{str} can not be translated (yet)"
      end

      def self.replace_context_env(var_name)
        # env context get mapped to environment variables
        "$#{var_name}"
      end

      def self.replace_context_vars(var_name)
        # env context get mapped to environment variables
        "$#{var_name}"
      end

      def self.replace_context_needs(path)
        job, context, *rest = path.split('.')
        case context
        when 'results'
          # return values are not the same, but it is a rough equivalent
          "$(buildkite-agent step get outcome --step '#{job}')"
        when 'outputs'
          replace_context_needs_outputs(job, rest)
        end
      end

      def self.replace_context_needs_outputs(job, path_list)
        if path_list.empty?
          # format of the resulting output is probably not the same
          "$(for KEY in $(buildkite-agent meta-data list | grep '^#{job}.')) do" \
            'buildkite-agent meta-data get "$KEY"; end)'
        elsif path_list.one?
          "$(buildkite-agent meta-data get '#{job}.#{path_list[0]}')"
        else
          "#{path_list} does not appear to be a valid step output"
        end
      end
    end

    class GithubExpressions
      def initialize
        @parser = ExpressionParser.new
        @transformer = ExpressionTransform.new(raise_on_unmatched: true)
      end

      def transform(str)
        @transformer.apply(@parser.parse(str))
      rescue Parslet::ParseFailed
        "Invalid expression #{str}"
      end
    end
  end
end
