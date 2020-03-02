require_relative "compat/renderer"
require_relative "compat/pipeline"
require_relative "compat/circleci"
require_relative "compat/travisci"

module BK
  module Compat
    VERSION = "0.1"

    PARSERS = [
      BK::Compat::CircleCI,
      BK::Compat::TravsiCI
    ]

    def self.guess(text)
      PARSERS.find do |parser|
        parser.matches?(text)
      end
    end
  end
end
