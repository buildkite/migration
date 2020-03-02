require_relative "compat/renderer"
require_relative "compat/pipeline"
require_relative "compat/circleci"

module BK
  module Compat
    VERSION = "0.1"

    PARSERS = [
      BK::Compat::CircleCI
    ]

    def self.guess(text)
      PARSERS.find do |parser|
        parser.matches?(text)
      end
    end
  end
end
