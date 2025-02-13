# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker installation commands
      class DockerOrb
        def translate_docker_install_docker_tools(config)
          steps = []

          steps.concat(translate_docker_install_docker(config)) if config['install-docker']
          steps.concat(translate_docker_install_docker_compose(config)) if config['install-docker-compose']
          steps.concat(translate_docker_install_dockerize(config)) if config['install-dockerize']
          steps.concat(translate_docker_install_goss(config)) if config['install-goss-dgoss']

          steps
        end
      end
    end
  end
end
