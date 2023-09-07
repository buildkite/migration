# frozen_string_literal: true

module BK
  module Compat
    # CircleCI orb handling
    class CircleCI
      private

      def load_orb(key, _conf)
        translator = CircleCISteps::GenericOrb.new(key)
        register_translator(*translator.register)
      end
    end

    module CircleCISteps
      # Generic orb steps/jobs (that states it is not supported)
      class GenericOrb
        def initialize(key)
          @prefix = key
        end

        def register
          [
            Regexp.new("^#{@prefix}/"),
            method(:translator)
          ]
        end

        private

        def translator(action, _config)
          [
            "# #{action} is part of orb #{@prefix} which is not supported and should be translated by hand"
          ]
        end
      end
    end
  end
end
