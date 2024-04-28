# frozen_string_literal: true

require 'digest'

module BK
  module Compat
    # extending class with some shared code
    class BitBucket
      def self.translate_conditional(conf)
        return [] if Hash(conf).empty?

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

      def self.translate_trigger(trigger, step)
        case trigger
        when 'manual'
          # ensure key is unique but deterministic
          k = step.key || Digest::SHA1.hexdigest(step.to_h.to_s)

          input = BK::Compat::InputStep.new(
            key: "execute-#{k}",
            prompt: "Execute step #{k}?"
          )
          step.depends_on = [input.key]

          [input, step]
        else
          step
        end
      end
    end
  end
end
