# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Handles the translation of github-last-commit-date
      class Translator
        def translate_github_last_commit_date(inputs)
          raise 'Invalid github-last-commit-date step configuration!' unless inputs.key?('repository_url')

          # commands = build_commands(inputs)
          BK::Compat::CommandStep.new(commands: build_commands(inputs))
        end

        private

        def build_commands(inputs)
          repo_dir = '$(mktemp -d)'
          commands = []
          commands << "git clone --depth 1 #{inputs['repository_url']} #{repo_dir}"
          commands << "cd #{repo_dir}"
          commands << 'LAST_COMMIT_DATE=$(git log -1 --format=%ci)'
          commands << <<~CMD.strip
            if [[ "$(uname)" == "Darwin" ]]; then
              LAST_COMMIT_DATE_NUMBERS=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$LAST_COMMIT_DATE" +'%y%m%d%H%M')
            else
              LAST_COMMIT_DATE_NUMBERS=$(date -d "$LAST_COMMIT_DATE" +'%y%m%d%H%M')
            fi
          CMD
          commands << 'echo "LAST_COMMIT_DATE=$LAST_COMMIT_DATE" >> $BUILDKITE_ENV'
          commands << 'echo "LAST_COMMIT_DATE_NUMBERS=$LAST_COMMIT_DATE_NUMBERS" >> $BUILDKITE_ENV'
          commands
        end
      end
    end
  end
end
