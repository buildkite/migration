# frozen_string_literal: true

require_relative 'compat/parsers'

module BK
  # Wrapper to try to guess compatibility parsers
  module Compat
    VERSION = '0.1'

    PARSERS = BK::Compat::Parsers.new.plugins

    def self.guess(text)
      PARSERS.find do |parser|
        parser.matches?(text)
      end
    end
  end
end
