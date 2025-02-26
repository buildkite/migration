# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        def translate_github_status(inputs)
          raise '# Invalid github-status step configuration!' unless required_github_status_inputs(inputs)

          params = extract_github_status_params(inputs)
          generate_github_status_script(params)
        end

        def extract_github_status_params(inputs)
          defaults = extract_defaults(inputs)
          transformed_values = extract_transformed_values(inputs)

          defaults.merge(transformed_values)
        end

        private

        def extract_defaults(inputs)
          {
            auth_token: inputs['auth_token'],
            commit_hash: inputs['commit_hash'],
            target_url: inputs['pipeline_build_url'] || inputs['build_url'] || '',
            description: inputs['description'] || '',
            context: inputs['context'] || 'default'
          }
        end

        def extract_transformed_values(inputs)
          {
            api_base_url: inputs['api_base_url']&.to_s&.chomp('/'),
            repo_path_command: extract_repo_path(inputs['repository_url']),
            state_command: determine_status(
              inputs['set_specific_status'],
              inputs['build_status'],
              inputs['pipeline_build_status']
            )
          }
        end

        def generate_github_status_script(params)
          <<~SCRIPT
            # GitHub Status API call
            #{params[:repo_path_command]}
            STATUS_API_URL="#{params[:api_base_url]}/repos/${REPO_PATH}/statuses/#{params[:commit_hash]}"
            echo "Sending status to: $STATUS_API_URL"
            curl -s -X POST \\
              -H "Authorization: token #{params[:auth_token]}" \\
              -H "Content-Type: application/json" \\
              --data '{
                "state": "#{params[:state_command]}",
                "target_url": "#{params[:target_url]}",
                "description": "#{params[:description]}",
                "context": "#{params[:context]}"
              }' \\
              "$STATUS_API_URL"
            CURL_RESULT=$?
            [ $CURL_RESULT -eq 0 ] || echo "Error sending status update to GitHub"
          SCRIPT
        end

        def determine_status(set_specific_status, build_status = nil, pipeline_build_status = nil)
          return set_specific_status unless set_specific_status == 'auto'

          pipeline_success = pipeline_build_status.nil? ||
                             pipeline_build_status == 'succeeded' ||
                             pipeline_build_status == 'succeeded_with_abort'

          if pipeline_success && build_status == '0'
            'success'
          else
            'failure'
          end
        end

        def extract_repo_path(repository_url)
          "REPO_PATH=$(echo \"#{repository_url}\" | sed -E 's|.*[:/]([^/]+/[^/.]+)(\\.git)?$|\\1|')"
        end

        def required_github_status_inputs(inputs)
          %w[auth_token api_base_url repository_url commit_hash].all? { |key| inputs.include?(key) }
        end
      end
    end
  end
end
