# frozen_string_literal: true

require_relative 'docker/docker'

module BK
  module Compat
    module CircleCISteps
      DockerOrb = BK::Compat::Parsers::CircleCI::Orbs::Docker::Docker
    end
  end
end
