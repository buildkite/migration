# frozen_string_literal: true

module BK
  module Compat
    # Plugin to use in a step
    class Plugin
      def initialize(path:, config: nil)
        @path = path
        @config = config
      end

      def to_h
        { @path => @config }
      end
    end
  end
end
