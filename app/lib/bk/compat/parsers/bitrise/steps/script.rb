# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Script step translation
      class Translator
        def translate_script(config)
          BK::Compat::CommandStep.new(
            commands: [config['inputs'].first['content']]
          )
        end
      end
    end
  end
end
