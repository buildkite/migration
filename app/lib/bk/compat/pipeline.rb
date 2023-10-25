# frozen_string_literal: true

require_relative 'renderer'
require_relative 'environment'

# for easier usage (modules just have to import)
require_relative 'pipeline/artifactpaths'
require_relative 'pipeline/plugin'
require_relative 'pipeline/step'

module BK
  module Compat
    # Base BuildKite pipeline
    class Pipeline
      attr_accessor :steps, :env

      def initialize(steps: [], env: {})
        @steps = steps
        @env = env
      end

      def render(*, **)
        BK::Compat::Renderer.new(to_h).render(*, **)
      end

      def to_h
        {}.tap do |h|
          h[:env] = @env.to_h unless @env.empty?
          h[:steps] = steps.map(&:to_h)
        end
      end
    end
  end
end
