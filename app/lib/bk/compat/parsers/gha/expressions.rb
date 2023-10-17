# frozen_string_literal: true

require 'parslet'

module BK
  module Compat
    # parse GHA expressions
    # https://docs.github.com/en/actions/learn-github-actions/expressions
    class ExpressionParser < Parslet::Parser
      rule(:space) { match('\s').repeat(1) }
      rule(:space?) { space.maybe }
      rule(:quote) { match('\'') }

      rule(:base_exp) { space? >> (parens | unary_op | functions | literals) >> space? }
      rule(:expression) { operations | base_exp }

      rule(:literals) { boolean.as(:bool) | null.as(:null) | number.as(:num) | string }
      rule(:boolean) { str('false') | str('true') }
      rule(:null) { str('null') }
      rule(:number) { match('[0-9]').repeat(1) } # TODO: support other numbers
      rule(:string) { quoted_string | unquoted_string.as(:str) }
      rule(:quoted_string) { quote >> (unquoted_string >> (str("''") >> unquoted_string).repeat).as(:str) >> quote }
      rule(:unquoted_string) { match('[^\']').repeat }

      rule(:parens) { str('(') >> expression >> str(')') }

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
  end
end
