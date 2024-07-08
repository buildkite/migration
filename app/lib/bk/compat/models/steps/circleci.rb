# frozen_string_literal: true

require_relative 'command'

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
        matrix = config.dig('matrix', 'parameters') || {}
        val = @parameters.each_with_object(value.dup) do |(name, param), str|
          possible = [
            config[name], # passed directly
            matrix.keys.include?(name) ? "{{ matrix.#{name} }}" : nil, # matrix params
            param['default'] # default parameter value
          ]
          str.gsub!(/<<\s*parameters\.#{name}\s*>>/, possible.compact.first)
        end
        val.gsub!(/<<\s*matrix\.([^\s]+)\s*>>/, '{{ matrix.\1 }}')

        val
      end

      def to_h
        @transformer = nil
        @parameters = nil
        super
      end
    end
  end
end
