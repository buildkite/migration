# frozen_string_literal: true

require_relative 'compat/circleci'
require_relative 'compat/travisci'

module BK
  # Wrapper to try to guess compatibility parsers
  module Compat
    VERSION = '0.1'

    # TODO: dynamic loading of these
    PARSERS = [
      BK::Compat::CircleCI,
      BK::Compat::TravisCI
    ]

    def self.guess(text)
      PARSERS.find do |parser|
        parser.matches?(text)
      end
    end
  end
end
