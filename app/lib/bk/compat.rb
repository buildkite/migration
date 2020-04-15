require_relative "compat/pipeline"
require_relative "compat/error"
require_relative "compat/circleci"
require_relative "compat/travisci"

module BK
  module Compat
    VERSION = "0.1"

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
