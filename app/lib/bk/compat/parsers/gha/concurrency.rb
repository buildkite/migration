# frozen_string_literal: true

module BK
  module Compat
    class GitHubActions
      def set_concurrency(bk_step, config)
        group, cancel_in_progress = normalize_concurrency(config['concurrency']) 
        # If cancel-in-progress was defined in the steps' concurrency hash
        bk_step.add_commands("# cancel-in-progress in Buildkite is the pipeline setting Cancel Intermediate Builds") unless cancel_in_progress.nil?
        # Set concurrency/concurrency_group
        bk_step.concurrency = 1 
        bk_step.concurrency_group = group
      end
  
      def normalize_concurrency(concurrency)
        case concurrency
        when String
          # Return the group name since the concurrency value is the group name
          [concurrency, nil]
        when Hash
          # Return the group name/cancel-in-progress values from the hash
          [concurrency['group'], concurrency['cancel-in-progress']]
        else
          raise TypeError, 'Invalid concurrency configuration'
        end
      end 
    end
  end
end
  