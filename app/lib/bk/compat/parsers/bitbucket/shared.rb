# frozen_string_literal: true

module BK
  module Compat
    # extending class with some shared code
    class BitBucket
      def self.translate_conditional(conf)
        return [] if conf.empty?

        globs = conf['changesets']['includePaths'].map { |p| "'#{p}'" }
        diff_cmd = 'git diff --exit-code --name-only HEAD "${BUILDKITE_PULL_REQUEST_BASE_BRANCH:HEAD^}"'

        BK::Compat::CommandStep.new(
          commands: [
            "if #{diff_cmd} -- #{globs.join(' ')}; then",
            "  echo '+++ :warning: no changes found in #{globs.join(' ')}, exiting step as OK",
            '  exit 0',
            'fi'
          ]
        )
      end
    end
  end
end
