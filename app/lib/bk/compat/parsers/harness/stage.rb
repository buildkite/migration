# frozen_string_literal: true

require_relative '../../models/steps/group'

module BK
  module Compat
    # Harness translation scaffolding
    class Harness
      def parse_stage(name:, identifier:, spec:, **rest)
        defaults = get_multi_level_keys(**rest)

        BK::Compat::GroupStep.new(
          label: name,
          key: identifier,
          steps: spec.dig('execution', 'steps').map do |step|
            @translator.translate_step(**defaults.merge(step['step']).transform_keys(&:to_sym))
          end
        )
      end

      # some keys can be defined on the stage or the step level
      # passing them through to just parse them at the step level
      def get_multi_level_keys(**spec)
        spec.slice(
          :strategy
        )
      end
    end
  end
end
