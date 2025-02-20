# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker installation commands
      class DockerOrb
        def translate_docker_check(config)
          docker_password = config.fetch('docker-password', 'DOCKER_PASSWORD')
          docker_username = config.fetch('docker-username', 'DOCKER_LOGIN')
          registry = config.fetch('registry', 'docker.io')
          [
            # Credential helper steps (if enabled)
            (if config.fetch('use-docker-credentials-store', false)
               [
                 translate_docker_install_docker_credential_helper(config.slice('arch')),
                 translate_docker_configure_docker_credentials_store({})
               ]
             end),
            # Docker login steps
            'echo "~~~ Checking Docker Login"',
            "echo \"${#{docker_password}}\"|docker login -u \"${#{docker_username}}\" --password-stdin \"#{registry}\""
          ].flatten.compact
        end
      end
    end
  end
end
