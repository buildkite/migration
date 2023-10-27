# frozen_string_literal: true

module BK
  module Compat
    class GitHubActions
      def set_branch_filters(bk_step, config)
        workflow_triggers = config.fetch('workflow_triggers', {})  
        on_push = extract_branch_filters(workflow_triggers, 'push') 
        bk_step.branches =  on_push&.join(" ")
      end 
 
      def extract_branch_filters(workflows, event)
        case workflows
        when Hash
          # Return the group name/cancel-in-progress values from the hash
          on_event = workflows.fetch(event, {}).nil? ? [] : workflows.fetch(event, {}) 
          return [] if on_event.empty?

          branches = transform_to_array(on_event.fetch('branches', {})) +
            transform_to_array(on_event.fetch('branches-ignore', {})).map { |branch| "!#{branch}" }  unless on_event.empty?
          branches.compact
        else
          []
        end
      end

      def transform_to_array(value)
        case value
        when String
          [value] 
        else
          # if we don't know how to do this, do nothing
          value
        end
      end

    end
  end
end
