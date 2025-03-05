# frozen_string_literal: true

require 'uri'

module BK
  module Compat
    module BitriseSteps
      # Handles the translation of github-release
      class Translator
        def translate_github_release(inputs)
          raise 'Invalid github-release step configuration!' unless validate_required_params(inputs)

          release_config = extract_release_config(inputs)
          repo_path = parse_repo(release_config['repository_url'])

          commands = []
          add_upload_commands(commands, release_config, repo_path) if release_config['files_to_upload']

          BK::Compat::CommandStep.new(commands: commands)
        end

        private

        def validate_required_params(inputs)
          %w[api_token username repository_url tag commit name].all? { |key| inputs.include?(key) }
        end

        def extract_release_config(inputs)
          defaults = {
            'body' => '',
            'draft' => 'yes',
            'pre_release' => 'no',
            'api_base_url' => 'https://api.github.com',
            'upload_base_url' => 'https://uploads.github.com',
            'generate_release_notes' => 'no'
          }

          defaults.merge(inputs)
        end

        def parse_repo(url)
          url = url.chomp('.git')

          if url.start_with?('git@')
            url = url.sub(':', '/')
            url = "ssh://#{url}"
          end

          uri = URI.parse(url)
          path_parts = uri.path.split('/').reject(&:empty?)

          raise 'Invalid repository URL!' if path_parts.size < 2

          owner, repo_name = path_parts[-2..]
          [owner, repo_name]
        end

        def add_upload_commands(commands, config, repo_path)
          commands << '# SECURITY NOTE: Storing API token in environment variable'
          commands << "export GITHUB_API_TOKEN='#{config['api_token']}'"
          config['files_to_upload'].split("\n").each do |file|
            file_path, file_name = file.split('|')
            file_name ||= "$(basename #{file_path})"

            upload_config = {
              api_token: config['api_token'],
              repo_path: repo_path,
              file_path: file_path,
              file_name: file_name,
              upload_base_url: config['upload_base_url']
            }

            commands << build_upload_asset_command(upload_config)
          end
        end

        def build_upload_asset_command(upload_config)
          <<~CMD.strip
            curl -X POST \\
            -H "Authorization: token $GITHUB_API_TOKEN" \\
            -H "Accept: application/vnd.github.v3+json" \\
            -H "Content-Type: application/octet-stream" \\
            --data-binary @#{upload_config[:file_path]} \\
            #{upload_config[:upload_base_url]}/repos/#{upload_config[:repo_path]}/releases/assets?name=#{upload_config[:file_name]}
          CMD
        end
      end
    end
  end
end
