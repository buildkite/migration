# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Handles the translation of github-status
      class Translator
        def translate_github_status(inputs)
          context = inputs['context'] || inputs['status_identifier'] || 'continuous-integration/buildkite'
          warnings = generate_warnings_for_unsupported_options(inputs.keys)

          github_status = {
            'context' => context
          }

          step = BK::Compat::CommandStep.new

          step.notify = [{ 'github_commit_status' => github_status }]
          step.add_commands(warnings) unless warnings.empty?

          step
        end

        private

        def generate_warnings_for_unsupported_options(input_keys)
          supported_options = ['status_identifier']
          warnings = []
          input_keys.each do |key|
            next if supported_options.include?(key)

            warnings << "# Warning: The '#{key}' option is not supported in Buildkite and will be ignored."
          end
          warnings
        end
      end
    end
  end
end
