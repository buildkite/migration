# frozen_string_literal: true

module BK
  module Compat
    # Generic plugin arch for parsers
    class Parsers
      @@plugins = [] # rubocop:disable Style/ClassVars

      def initialize
        current_folder = File.dirname(__FILE__)
        Dir.glob(File.join(current_folder, 'parsers', '*.rb')).each do |file|
          require_relative file
        end
      end

      def self.register_plugin(plugin)
        @@plugins << plugin
      end

      def plugins
        @@plugins
      end

    end
  end
end
