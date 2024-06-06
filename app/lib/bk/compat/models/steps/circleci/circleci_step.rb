# frozen_string_literal: true

module BK
  module Compat
    # wrapper class to setup parameters
    class CircleCIStep < CommandStep
      attr_accessor :transformer, :parameters

      def initialize(*, **)
        super
        @transformer = method(:circle_ci_params)
      end

      def hash_attributes
        super + ['parameters']
      end

      def circle_ci_params(value, config)
        return value if @parameters.empty?

        @parameters.each_with_object(value.dup) do |(name, param), str|
          val = config.fetch(name, param.fetch('default', nil))
          str.sub!(/<<\s*parameters\.#{name}\s*>>/, val)
        end
      end

      def to_h
        @transformer = nil
        @parameters = nil
        super
      end
    end
  end
end
