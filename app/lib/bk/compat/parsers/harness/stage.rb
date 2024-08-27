# frozen_string_literal: true

require_relative '../../models/steps/group'

module BK
  module Compat
    # Harness translation scaffolding
    class Harness
      def parse_stage(name:, identifier:, spec:, **_rest)
        grp = BK::Compat::GroupStep.new(
          label: name,
          key: identifier,
          steps: spec.dig('execution', 'steps').map do |step|
            @translator.translate_step(**step['step'].transform_keys(&:to_sym))
          end
        )

        simplify_group(grp)
      end

      def simplify_group(group)
        # If there ended up being only 1 stage, skip the group and just
        # pull the steps out.
        if group.steps.length == 1
          step = group.steps.first
          step.conditional = group.conditional
          group = step
        end
        group
      end
    end
  end
end
