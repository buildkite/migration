# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        VALID_STEP_TYPES = %w[bundler brew-install change-workdir git-clone git-tag script github-status].freeze

        def matcher(type, _inputs)
          VALID_STEP_TYPES.include?(type.downcase)
        end

        def translator(type, inputs)
          send("translate_#{type.downcase.gsub('-', '_')}", inputs)
        end

        def translate_brew_install(inputs)
          return '# Invalid brew-install configuration!' unless inputs.include?('verbose_log')

          generate_brew_install_command(inputs)
        end

        def generate_brew_install_command(inputs)
          if inputs['packages']
            install_type = inputs.fetch('upgrade', false) ? 'reinstall' : 'install'
            "brew #{install_type}#{inputs['verbose_log'] ? ' -vd' : nil} #{inputs['packages']}"
          elsif inputs['use_brewfile'] && inputs['brewfile_path']
            "brew bundle#{inputs['verbose_log'] ? ' -vd' : nil} --file=#{inputs['brewfile_path']}"
          else
            # verbose_log defined, packages and use_brewfile/brewfile_path not defined - invalid
            '# Invalid brew-install configuration!'
          end
        end

        def translate_bundler(inputs)
          return '# Invalid bundler step configuration!' unless required_bundler_inputs(inputs)

          install_jobs = inputs['bundle_install_jobs']
          install_retry = inputs['bundle_install_retry']

          "bundle check || bundle install --jobs #{install_jobs} --retry #{install_retry}"
        end

        def required_bundler_inputs(inputs)
          inputs.include?('bundle_install_jobs') && inputs.include?('bundle_install_retry')
        end

        def translate_change_workdir(inputs)
          return '# Invalid change-workdir step configuration!' unless inputs.include?('path')

          [
            inputs['is_create_path'] ? "mkdir #{inputs['path']}" : nil,
            "cd #{inputs['path']}"
          ].compact
        end

        def translate_git_clone(_inputs)
          '# No need for cloning, the agent takes care of that'
        end

        def translate_git_tag(inputs)
          return '# Invalid git-tag step configuration!' unless inputs.include?('tag')

          [
            "git tag -fa #{inputs['tag']} -m \"#{inputs['tag_message']}\"",
            inputs['push'] ? 'git push --tags' : nil
          ].compact
        end

        def translate_script(inputs)
          inputs['content']
        end

        def translate_github_status(inputs)
          return '# Invalid github-status step configuration!' unless required_github_status_inputs(inputs)

          params = extract_github_status_params(inputs)
          generate_github_status_script(params)
        end

        def extract_github_status_params(inputs)
          {
            auth_token: inputs['auth_token'],
            api_base_url: inputs['api_base_url'].to_s.chomp('/'),
            repo_path_command: extract_repo_path(inputs['repository_url']),
            commit_hash: inputs['commit_hash'],
            state_command: determine_status(inputs['set_specific_status']),
            target_url: inputs['pipeline_build_url'] || inputs['build_url'] || '',
            description: inputs['description'] || '',
            context: inputs['context'] || 'default'
          }
        end

        def generate_github_status_script(params)
          <<~SCRIPT
            # GitHub Status API call
            # Extract owner/repo from repository URL
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

        def determine_status(set_specific_status)
          return set_specific_status unless set_specific_status == 'auto'

          "'$([ \"$BUILDKITE_COMMAND_EXIT_STATUS\" = \"0\" ] && echo \"success\" || echo \"failure\")'"
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
