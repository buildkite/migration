# frozen_string_literal: true

module BK
  module Compat
    # Command step extensions
    class CommandStep < BaseStep
      def agent_targeting=(targeting)
        return if targeting.nil? || targeting['stack'].nil?

        @agents ||= {}
        @agents[:stack] = targeting['stack']
      end
    end
  end
end
