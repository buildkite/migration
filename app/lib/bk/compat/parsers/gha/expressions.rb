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

      rule(:expression) { literals | parens | operators | functions }

      rule(:literals) { boolean | null | number | string }
      rule(:boolean) { str('false') | str('true') }
      rule(:null) { str('null') }
      rule(:number) { match('[0-9]').repeat(1) } # TODO: support other numbers
      rule(:string) { quoted_string | unquoted_string }
      rule(:quoted_string) { quote >> (unquoted_string | match('\'\'')).repeat >> quote }
      rule(:unquoted_string) { match('[^\']').repeat }

      rule(:parens) { match('(') >> space? >> expression >> space? >> match(')') }

      rule(:operators) { ops | unary | logical }
      rule(:ops) { expression >> space? >> operators >> space? >> expression }
      rule(:unary) { match('!') >> space? >> expression } # can not name it "not"
      rule(:operators) do
        match('<=') |
          match('<') |
          match('>=') |
          match('>') |
          match('==') |
          match('!=') |
          match('&&') |
          match('||')
      end

      rule(:functions) { arg_functions | status_functions }

      rule(:arg_functions) { func_name >> match('(') >> space? >> arguments >> space? >> match(')') }
      rule(:arguments) { expression >> (match(',') >> space? >> expression).repeat }
      rule(:func_name) do
        match('contains') |
          match('startsWith') |
          match('endsWith') |
          match('format') |
          match('join') |
          match('toJSON') |
          match('fromJSON') |
          match('hashFiles')
      end
      rule(:status_functions) { status_func >> match('(') >> space? >> match(')') }
      rule(:status_func) do
        match('success') |
          match('always') |
          match('cancelled') |
          match('failure')
      end

      root(:expression)
    end
  end
end
