# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker/check command
      class DockerOrb
        def translate_docker_check(config)
          docker_password = config.fetch('docker-password', 'DOCKER_PASSWORD')
          docker_username = config.fetch('docker-username', 'DOCKER_LOGIN')
          registry = config.fetch('registry', 'docker.io')

          [
            (if config.fetch('use-docker-credentials-store', false)
               [
                 translate_docker_install_docker_credential_helper({ 'arch' => config.fetch('arch', 'amd64') }),
                 translate_docker_configure_docker_credentials_store({})
               ]
             end),
            'echo "~~~ Checking Docker Login"',
            "echo \"#{docker_password}\" | docker login -u \"#{docker_username}\" --password-stdin \"#{registry}\""
          ].flatten.compact
        end
      end
    end
  end
end
