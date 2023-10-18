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

      rule(:literals) { boolean.as(:bool) | null.as(:null) | number.as(:num) | string }
      rule(:boolean) { str('false') | str('true') }
      rule(:null) { str('null') }

      rule(:number) { signed_integer | float | hex | exp }
      rule(:integer) { match('[0-9]').repeat(1) }
      rule(:signed_integer) { str('-').maybe >> integer }
      rule(:float) { signed_integer >> str('.') >> integer }
      rule(:hex) { str('0x') >> match('[0-9a-f]').repeat(1) }
      rule(:exp) { float >> match('[eE]') >> signed_integer }

      # Docs state that strings must be quoted (unless they are not surrounded with ${{ }})
      rule(:string) do
        quote >> (UnquotedStringParser.new >> (str("''") >> UnquotedStringParser.new).repeat).as(:str) >> quote
      end

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

      rule(:arg_functions) { func_name.as(:func) >> str('(') >> arguments.as(:args) >> str(')') }
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

      root(:expression)
    end

    # Unquoted strings are just characters that don't have single quotes
    class UnquotedStringParser < Parslet::Parser
      root(:unquoted_string)
      rule(:unquoted_string) { match('[^\']').repeat }
    end
  end
end
