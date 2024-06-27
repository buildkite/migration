# frozen_string_literal: true

module BK
  module Compat
    # Harness translation of stages
    class Harness
      def parse_stage(name:, identifier:, spec:, **_rest)
        BK::Compat::GroupStep.new(
          label: name,
          key: identifier,
          steps: spec.dig('execution', 'steps').map do |step|
            @translator.translate_step(**step['step'].transform_keys(&:to_sym))
          end
        )
      end
    end
  end
end
