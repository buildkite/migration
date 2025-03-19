# frozen_string_literal: true

module BK
  module Compat
    # Command step extensions
    class CommandStep < BaseStep
      def stack=(stack_value)
        return if stack_value.nil?

        @agents ||= {}
        @agents[:stack] = stack_value if stack_value
      end

      def agent_targeting=(targeting)
        return if targeting.nil? || targeting['stack'].nil?

        @agents ||= {}
        @agents[:stack] = targeting['stack']
      end
    end
  end
end
