# frozen_string_literal: true

require_relative '../renderer'
require_relative '../models/steps/group'

module BK
  module Compat
    # Base BuildKite pipeline
    class Pipeline
      attr_accessor :steps, :env

      def initialize(steps: [], env: {}, agent_targeting: nil)
        @steps = steps
        @env = env
        @agent_targeting = agent_targeting
      end

      def render(*, **)
        BK::Compat::Renderer.new(to_h).render(*, **)
      end

      def simplify_steps
        first = @steps.first
        # bubble up a pipeline with a single group that has no conditional
        @steps = first.steps if @steps.one? && first.is_a?(GroupStep) && !first.conditional

        @steps.map { |s| s.simplify.to_h }
      end

      def to_h
        {}.tap do |h|
          h[:env] = @env unless @env.empty?
          h[:steps] = simplify_steps
          # Add agent targeting if it exists
          h[:agent] = convert_agent_targeting(@agent_targeting) if @agent_targeting
        end
      end

      def convert_agent_targeting(targeting)
        return nil unless targeting

        targeting_strings = []

        # Convert stack to Buildkite agent targeting
        targeting_strings << "stack=#{targeting['stack']}" if targeting['stack']
        targeting_strings.join(' ')
      end
    end
  end
end
