# frozen_string_literal: true

module BK
  module Compat
    # unsupported feature
    module Error
      class CompatError < StandardError; end

      class ParseError < CompatError; end

      class NotSupportedError < CompatError; end

      class ConfigurationError < CompatError; end
    end
  end
end
