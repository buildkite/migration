# frozen_string_literal: true

require_relative 'renderer'
require_relative 'environment'

# for easier usage (modules just have to import)
require_relative 'pipeline/plugin'
require_relative 'pipeline/step'

module BK
  module Compat
    # Base BuildKite pipeline
    class Pipeline
      attr_accessor :steps, :env

      def initialize(steps: [], env: nil)
        @steps = steps
        @env = env
      end

      def render(**args)
        BK::Compat::Renderer.new(to_h).render(**args)
      end

      def to_h
        {}.tap do |h|
          h[:env] = @env.to_h if @env
          h[:steps] = steps.map(&:to_h)
        end
      end
    end
  end
end
