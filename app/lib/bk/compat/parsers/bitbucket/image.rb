# frozen_string_literal: true

module BK
  module Compat
    module BitBucketSteps
      # Implementation of image-related key translations
      class Step
        def translate_image(image)
          return [] if image.nil?

          BK::Compat::Plugin.new(
            name: 'docker',
            config: {
              'image' => image.to_s
            }
          )
        end
      end
    end
  end
end
