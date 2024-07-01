# frozen_string_literal: true

require_relative 'steps/script'

module BK
  module Compat
    module BitriseSteps
      # Implementation of native step translation
      class Translator
        VALID_STEP_TYPES = %w[script].freeze

        def matcher(type, _config)
          VALID_STEP_TYPES.include?(type.downcase)
        end

        def translator(type, config)
          send("translate_#{type.downcase.gsub('-', '_')}", config)
        end
      end
    end
  end
end
