# frozen_string_literal: true

module BK
    module Compat
      module CircleCISteps
        # Handles the translation of docker installation commands
        class DockerOrb
          def translate_docker_install_docker_tools(config)
            [
              (translate_docker_install_docker(config) if config['install-docker']),
              (translate_docker_install_docker_compose(config) if config['install-docker-compose']),
              (translate_docker_install_dockerize(config) if config['install-dockerize']),
              (translate_docker_install_goss(config) if config['install-goss-dgoss'])
            ].compact.flatten
          end
        end
      end
    end
  end  