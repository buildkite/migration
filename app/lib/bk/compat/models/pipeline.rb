# frozen_string_literal: true

require_relative '../renderer'
require_relative '../models/steps/group'

module BK
  module Compat
    # Base BuildKite pipeline
    class Pipeline
      attr_accessor :agents, :steps, :env

      def initialize(steps: [], env: {}, agents: {})
        @steps = steps
        @env = env
        @agents = agents || {} # Ensure @agents is always initialized
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
          h[:agents] = @agents unless @agents.empty?
        end
      end
    end
  end
end
