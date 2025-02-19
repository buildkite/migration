# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of configure-docker-credentials-store command
      class DockerOrb
        def translate_docker_configure_docker_credentials_store(config)
          docker_config_path = config.fetch('docker-config-path', '$HOME/.docker/config.json')
          helper_name = config.fetch('helper-name', '')

          [
            "echo '~~~ Configuring Docker Credentials Store'",
            "DOCKER_CONFIG_PATH=\"#{docker_config_path}\"",
            "HELPER_NAME=\"#{helper_name}\"",
            'if [ -z "$HELPER_NAME" ]; then',
            '  if [ "$(uname -s)" = "Darwin" ]; then',
            '    HELPER_NAME="osxkeychain"',
            '  else',
            '    HELPER_NAME="pass"',
            '  fi',
            'fi',
            'if [ ! -e "$DOCKER_CONFIG_PATH" ]; then',
            '  mkdir -p "$(dirname "$DOCKER_CONFIG_PATH")"',
            'fi',
            'if ! command -v jq >/dev/null 2>&1; then',
            '  echo "jq is required for this command"',
            '  exit 1',
            'fi',
            'jq --arg credsStore "$HELPER_NAME" \'. + {credsStore: $credsStore}\' "$DOCKER_CONFIG_PATH" > ' \
            '/tmp/docker-config-credsstore-update.json',
            'mv /tmp/docker-config-credsstore-update.json "$DOCKER_CONFIG_PATH"'
          ].compact
        end
      end
    end
  end
end
