# frozen_string_literal: true

require_relative 'jobs'

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      # for branch filtering
      def self.build_condition(filters, key)
        only = logic_builder(key, '=', string_or_list(filters.fetch('only', [])), ' || ')
        ignore = logic_builder(key, '!', string_or_list(filters.fetch('ignore', [])), ' && ')

        BK::Compat.xxand(only, ignore)
      end

      def self.logic_builder(key, operator, elements, joiner)
        elements.map do |spec|
          negator = spec.start_with?('/') ? '~' : '='
          "#{key} #{operator}#{negator} #{spec}"
        end.join(joiner)
      end

      def self.parse_condition(tree)
        tree.is_a?(String) ? tree : condition_map(tree)
      end

      def self.condition_map(tree)
        raise 'A condition operator must be a single-keyed dictionary' unless tree.length == 1

        op = tree.keys.first
        case op
        when 'and'
          tree[op].map { |elem| parse_condition(elem) }.join(' && ')
        when 'or'
          tree[op].map { |elem| parse_condition(elem) }.join(' || ')
        when 'not'
          val = parse_condition(tree[op])
          "!(#{val})"
        when 'equal'
          condition_equal(*tree[op])
        when 'matches'
          "/#{tree[op]['pattern']}/ ~= #{tree[op]['value']}"
        else
          raise "Invalid conditional operation #{op}"
        end
      end

      def self.condition_equal(first_val, *rest)
        rest.product([first_val]).map { |a, b| "#{string_or_key(a)} == #{string_or_key(b)}" }.join(' && ')
      end

      def self.string_or_list(object)
        object.is_a?(String) ? [object] : object
      end

      def self.string_or_key(object)
        object.is_a?(Hash) ? object.keys.first : object
      end
    end
  end
end
