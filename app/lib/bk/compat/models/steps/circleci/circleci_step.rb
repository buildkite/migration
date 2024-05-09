# frozen_string_literal: true

require_relative '../command'

module BK
  module Compat
    class CircleCIStep < BK::Compat::CommandStep
      def initialize(*, **)
        super
        @transformer = method(:circle_ci_params)
      end
      def circle_ci_params(value, config)
        return value if @parameters.empty?
        @parameters.each_with_object(value.dup) do |(name, param), str|
          val = config.fetch(name, param.fetch('default', nil))
          str.sub!(/<<\s*parameters\.#{name}\s*>>/, val)
        end
      end
    end
  end
end
 