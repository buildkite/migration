# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Handles the translation of github-status
      class Translator
        def translate_github_status(inputs)
          context = inputs['status_identifier'] || 'continuous-integration/buildkite'
          unless inputs.empty?
            warnings = '# Only the status_identifier option is supported for github status translation'
          end

          BK::Compat::CommandStep.new(
            notify: [{ 'github_commit_status' => { 'context' => context } }],
            commands: [warnings].compact
          )
        end
      end
    end
  end
end
