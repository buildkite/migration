# frozen_string_literal: true

require_relative 'orbs/docker'
require_relative '../../models/steps/circleci'

module BK
  module Compat
    module CircleCISteps
      # Generic orb steps/jobs (that states it is not supported)
      class GenericOrb
        def initialize(key)
          @prefix = key
        end

        def matcher?(orb, _conf)
          orb.start_with?("#{@prefix}/")
        end

        def translator(action, config)
          BK::Compat::CircleCIStep.new(
            key: config['name'] || action,
            commands: [
              "# #{action} is part of orb #{@prefix} which is not supported and should be translated by hand"
            ]
          )
        end
      end
    end
  end
end
