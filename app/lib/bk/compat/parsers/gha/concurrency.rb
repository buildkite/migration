# frozen_string_literal: true

module BK
  module Compat
    class GitHubActions
      def set_concurrency(bk_step, config)
        group, cancel_in_progress = obtain_concurrency(config['concurrency']) 
        # If cancel-in-progress was defined in the steps' concurrency hash
        bk_step << ["# The concurrency setting of `cancel-in-progress: #{cancel_in_progress}` for this step is not supported. Please use Cancel Intermediate Builds."] if !cancel_in_progress.nil?
        # Set concurrency/concurrency_group
        bk_step.concurrency = 1 
        bk_step.concurrency_group = group
      end
  
      def obtain_concurrency(concurrency)
        case concurrency
        when String
          [concurrency, nil]
        when Hash
          # Convert the hash to an key/value array
          concurrency_arr = concurrency.to_a
          # Extract the group name and cancel-in-progress values (latter if the array length is 2)
          group = concurrency_arr.first.last
          cancel_in_progress = concurrency_arr.length == 2 ? concurrency_arr.last.last : nil
          # Return the group name/cancel-in-progress value]
          [group, cancel_in_progress]
        end
      end 
    end
  end
end
  