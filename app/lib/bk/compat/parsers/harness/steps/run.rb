# frozen_string_literal: true

require_relative '../../../pipeline/step'

module BK
  module Compat
    module HarnessSteps
      # Implementation of native step translation
      class Translator
        def translate_run(name:, identifier:, spec:, **_rest)
          cmd = BK::Compat::CommandStep.new(
            label: name,
            key: identifier,
            commands: [spec['command']]
          )
          cmd << translate_image(spec['image'])      
          cmd
        end

        def translate_image(image) 
          p image
          return nil if image.nil?

          BK::Compat::Plugin.new(
            name: 'docker',
            config: {
              'image' => image,
            }.compact
          )
        end
        
      end
    end
  end
end
