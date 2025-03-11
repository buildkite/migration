# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Handles the translation of github-last-commit-date
      class Translator
        def translate_github_last_commit_date(_inputs)
          BK::Compat::CommandStep.new(commands: build_commands)
        end

        private

        def build_commands
          [
            'LAST_COMMIT_DATE=$(git log -1 --format=%ci)',
            'if [[ "$(uname)" == "Darwin" ]]; then',
            '  LAST_COMMIT_DATE_NUMBERS=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$LAST_COMMIT_DATE" +"%y%m%d%H%M")',
            'else',
            '  LAST_COMMIT_DATE_NUMBERS=$(date -d "$LAST_COMMIT_DATE" +"%y%m%d%H%M")',
            'fi',
            'buildkite-agent meta-data set "LAST_COMMIT_DATE" "$LAST_COMMIT_DATE"',
            'buildkite-agent meta-data set "LAST_COMMIT_DATE_NUMBERS" "$LAST_COMMIT_DATE_NUMBERS"'
          ]
        end
      end
    end
  end
end
