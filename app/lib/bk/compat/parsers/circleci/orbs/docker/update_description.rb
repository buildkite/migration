# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of update-description command
      class DockerOrb
        def translate_docker_update_description(config)
          docker_username = config.fetch('docker-username', 'DOCKER_LOGIN')
          docker_password = config.fetch('docker-password', 'DOCKER_PASSWORD')
          image = config.fetch('image', '')
          path = config.fetch('path', '.')
          readme = config.fetch('readme', 'README.md')
          registry = config.fetch('registry', 'docker.io')

          [
            "echo '~~~ Updating Docker Hub Description'",
            "if [ \"#{registry}\" != \"docker.io\" ]; then",
            '  echo "Registry is not set to Docker Hub. Exiting."',
            '  exit 1',
            'fi',
            '',
            "USERNAME=${#{docker_username}}",
            "PASSWORD=${#{docker_password}}",
            "IMAGE=\"#{image}\"",
            "DESCRIPTION=\"#{path}/#{readme}\"",
            '',
            'echo "Authenticating with Docker Hub..."',
            'PAYLOAD="username=$USERNAME&password=$PASSWORD"',
            'JWT=$(curl -s -d "$PAYLOAD" https://hub.docker.com/v2/users/login/ | jq -r .token)',
            '',
            'HEADER="Authorization: JWT $JWT"',
            'URL="https://hub.docker.com/v2/repositories/$IMAGE/"',
            '',
            'STATUS=$(curl -s -o /dev/null -w "%<http_code>s" -X PATCH -H "$HEADER"  ' \
            '-H "Content-type: application/json" --data "{\"full_description\": $(jq -Rs . $DESCRIPTION)}" $URL)',
            '',
            'if [ "$STATUS" -ne 200 ]; then',
            '  echo "Could not update image description"',
            '  echo "Error code: $STATUS"',
            '  exit 1',
            'fi',
            'echo "Docker image description updated successfully."'
          ].compact
        end
      end
    end
  end
end
