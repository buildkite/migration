# frozen_string_literal: true

module BK
  module Compat
    # translate branches
    class GitHubActions
      def translate_branch_filters(triggers)
        return [] unless triggers.is_a?(Hash)

        push_trigger = triggers.fetch('push', {})

        # apparently "push:" is a valid syntax
        return [] if push_trigger.nil?

        inc = [push_trigger.fetch('branches', [])].flatten
        exc = [push_trigger.fetch('branches-ignore', [])].flatten

        branches = inc + exc.map { |branch| "!#{branch}" }
        branches.join(' ')
      end
    end
  end
end
