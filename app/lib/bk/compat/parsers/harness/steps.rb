# frozen_string_literal: true

require_relative 'steps/approval'
require_relative 'steps/background'
require_relative 'steps/run'

module BK
  module Compat
    module HarnessSteps
      # Implementation of native step translation
      class Translator
        VALID_TYPES = %w[background harnessapproval run].freeze

        def matcher(type:, **_rest)
          VALID_TYPES.include?(type.downcase)
        end

        def translator(type:, **)
          send("translate_#{type.downcase.gsub('-', '_')}", **)
        end
      end
    end
  end
end
