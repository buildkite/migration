# frozen_string_literal: true

require_relative 'steps'
require_relative '../../models/steps/gha'

module BK
  module Compat
    # translate concurrency configurations
    class GitHubActions
      def translate_concurrency(config)
        return [] if config.nil?

        group, cancel_in_progress = normalize_concurrency(config)

        BK::Compat::GHAStep.new(
          concurrency: 1,
          concurrency_group: group
        ).tap do |bk_step|
          unless cancel_in_progress.nil?
            # If cancel-in-progress was defined in the steps' concurrency hash
            bk_step.add_commands(
              '# cancel-in-progress in Buildkite is the pipeline setting Cancel Intermediate Builds'
            )
          end
        end
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
