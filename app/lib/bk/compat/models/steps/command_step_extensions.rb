# frozen_string_literal: true

module BK
  module Compat
    # Command step extensions
    class CommandStep < BaseStep
      def stack
        @agents&.dig(:stack)
      end

      def stack=(stack_value)
        return if stack_value.nil?

        @agents ||= {}
        @agents[:stack] = stack_value
      end
    end
  end
end
