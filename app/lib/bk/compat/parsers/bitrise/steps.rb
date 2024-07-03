# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        VALID_STEP_TYPES = %w[script].freeze

        def matcher(type, _config)
          VALID_STEP_TYPES.include?(type.downcase)
        end

        def translator(type, config)
          send("translate_#{type.downcase.gsub('-', '_')}", config)
        end

        def translate_script(config)
          [
            config['inputs'].first['content']
          ]
        end
      end
    end
  end
end
