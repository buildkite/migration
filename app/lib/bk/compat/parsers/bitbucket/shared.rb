# frozen_string_literal: true

require 'digest'

require_relative '../../models/steps/command'
require_relative '../../models/steps/input'

module BK
  module Compat
    # extending class with some shared code
    class BitBucket
      def self.step_id(step)
        # key is unique, but not mandatory so hash the step
        [step].flatten[0].key || Digest::SHA1.hexdigest(step.to_h.to_s)
      end

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

      def self.translate_trigger(trigger, next_steps)
        steps = Array(next_steps)

        case trigger
        when 'manual'
          # ensure key is unique but deterministic
          k = step_id(steps[0])

          input = BK::Compat::InputStep.new(
            key: "execute-#{k}",
            prompt: "Execute step #{k}?"
          )
          steps.each { |s| s.depends_on << input.key unless s.is_a?(WaitStep) }

          [input].concat(steps)
        else
          steps
        end
      end
    end
  end
end
