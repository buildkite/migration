# frozen_string_literal: true

require 'yaml'

module BK
  module Compat
    # unsupported feature
    module Error
      class ParseError < StandardError; end

      # Base compatibility error with YAML parsing support
      class CompatError < ParseError
        def self.safe_yaml
          yield
        rescue Psych::SyntaxError => e
          raise new("Invalid YAML syntax: #{e.message}")
        end
      end

      class NotSupportedError < CompatError; end

      class ConfigurationError < CompatError; end
    end
  end
end
