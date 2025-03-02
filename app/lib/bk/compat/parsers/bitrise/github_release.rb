# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Handles the translation of github-release
      class Translator
        def translate_github_release(inputs)
          raise 'Invalid github-release step configuration!' unless validate_required_params(inputs)

          release_config = extract_release_config(inputs)
          owner, repo_name = parse_repo(release_config[:repository_url])

          commands = build_commands(release_config, owner, repo_name)
          BK::Compat::CommandStep.new(commands: commands)
        end

        private

        def validate_required_params(inputs)
          %w[api_token username repository_url tag commit name].all? { |key| inputs.include?(key) }
        end

        def extract_release_config(inputs)
          {
            api_token: inputs['api_token'],
            commit: inputs['commit'],
            name: inputs['name'],
            repository_url: inputs['repository_url'],
            tag: inputs['tag'],
            body: inputs['body'] || '',
            draft: inputs['draft'] || 'yes',
            pre_release: inputs['pre_release'] || 'no',
            files_to_upload: inputs['files_to_upload'],
            api_base_url: inputs['api_base_url'] || 'https://api.github.com',
            upload_base_url: inputs['upload_base_url'] || 'https://uploads.github.com',
            generate_release_notes: inputs['generate_release_notes'] || 'no'
          }
        end

        def parse_repo(url)
          url.chomp!('.git')

          case url
          when %r{^https://}, /^git@/, %r{^ssh://}
            url = url.sub(%r{^(https://|git@|ssh://)}, '')
            _, repo = url.split(%r{[:/]}, 2)
          end

          owner, repo_name = repo&.split('/') || []
          raise 'Invalid repository URL!' if owner.nil? || repo_name.nil?

          [owner, repo_name]
        end

        def build_commands(config, owner, repo_name)
          commands = []
          commands << "git clone #{config[:repository_url]} /tmp/bitrise-ex"
          commands << './build-app.sh'

          add_upload_commands(commands, config, owner, repo_name) if config[:files_to_upload]

          commands
        end

        def add_upload_commands(commands, config, owner, repo_name)
          config[:files_to_upload].split("\n").each do |file|
            file_path, file_name = file.split('|')
            file_name ||= File.basename(file_path)

            upload_config = {
              api_token: config[:api_token],
              owner: owner,
              repo: repo_name,
              file_path: file_path,
              file_name: file_name,
              upload_base_url: config[:upload_base_url]
            }

            commands << build_upload_asset_command(upload_config)
          end
        end

        def build_upload_asset_command(upload_config)
          <<~CMD.strip
            curl -X POST \\
            -H "Authorization: token #{upload_config[:api_token]}" \\
            -H "Accept: application/vnd.github.v3+json" \\
            -H "Content-Type: application/octet-stream" \\
            --data-binary @#{upload_config[:file_path]} \\
            #{upload_config[:upload_base_url]}/repos/#{upload_config[:owner]}/#{upload_config[:repo]}/releases/assets?name=#{upload_config[:file_name]}
          CMD
        end
      end
    end
  end
end
