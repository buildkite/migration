# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Handles the translation of github-status
      class Translator
        def translate_github_status(inputs)
          raise '# Invalid github-status step configuration!' unless required_github_status_inputs(inputs)

          params = extract_github_status_params(inputs)
          BK::Compat::CommandStep.new(notify: generate_github_status_notify(params))
        end

        private

        def extract_github_status_params(inputs)
          {
            context: inputs['context'] || 'default',
            description: inputs['description'] || '',
            status: determine_status(
              inputs['set_specific_status'],
              inputs['build_status'],
              inputs['pipeline_build_status']
            ),
            target_url: inputs['pipeline_build_url'] || inputs['build_url'] || '${BUILDKITE_BUILD_URL}'
          }
        end

        def generate_github_status_notify(params)
          [
            {
              'github_commit_status' => {
                'context' => params[:context],
                'description' => params[:description],
                'status' => params[:status],
                'target_url' => params[:target_url]
              }
            }
          ]
        end

        def determine_status(set_specific_status, build_status = nil, pipeline_build_status = nil)
          return set_specific_status unless set_specific_status == 'auto'

          pipeline_success = pipeline_build_status.nil? || pipeline_build_status == 'passed'

          if pipeline_success && build_status == '0'
            'success'
          else
            'failure'
          end
        end

        def required_github_status_inputs(inputs)
          %w[context description set_specific_status].all? { |key| inputs.include?(key) }
        end
      end
    end
  end
end
