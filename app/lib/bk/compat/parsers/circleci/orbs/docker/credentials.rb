# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of configure docker credentials store and install docker credential helper commands
      class DockerOrb
        def translate_docker_configure_docker_credentials_store(config)
          docker_config_path = config.fetch('docker-config-path', '$HOME/.docker/config.json')
          helper_name = config.fetch('helper-name', '')

          [
            "echo '~~~ Configuring Docker Credentials Store'",
            "DOCKER_CONFIG_PATH=\"#{docker_config_path}\"",
            "HELPER_NAME=\"#{helper_name}\"",
            'if [ -z "${HELPER_NAME}" ]; then',
            '  if [ "$(uname -s)" = "Darwin" ]; then',
            '    HELPER_NAME="osxkeychain"',
            '  else',
            '    HELPER_NAME="pass"',
            '  fi',
            'fi',
            'if [ ! -e "${DOCKER_CONFIG_PATH}" ]; then',
            '  mkdir -p "$(dirname "${DOCKER_CONFIG_PATH}")"',
            'fi',
            'if ! command -v jq >/dev/null 2>&1; then',
            '  echo "jq is required for this command"',
            '  exit 1',
            'fi',
            'jq --arg credsStore "${HELPER_NAME}" \'. + {credsStore: ${credsStore}}\' "${DOCKER_CONFIG_PATH}" > ' \
            '/tmp/docker-config-credsstore-update.json',
            'mv /tmp/docker-config-credsstore-update.json "${DOCKER_CONFIG_PATH}"'
          ]
        end

        def translate_docker_install_docker_credential_helper(config)
          arch = config.fetch('arch', 'amd64')
          helper_name = config.fetch('helper-name', '')
          release_tag = config.fetch('release-tag', '')

          [
            '# Instead of installing docker credential helper in a step, ',
            '# we recommend your agent environment to have it pre-installed',
            "echo '~~~ Installing Docker Credential Helper'",
            'platform=""',
            "arch=\"#{arch}\"",
            "helper_name=\"#{helper_name}\"",
            "release_tag=\"#{release_tag}\"",
            'if [ "$(uname -s)" = "Darwin" ]; then',
            '  platform="darwin"',
            '  arch="arm64"',
            'else',
            '  platform="linux"',
            'fi',
            'if [ -z "${helper_name}" ]; then',
            '  if [ "${platform}" = "darwin" ]; then',
            '    helper_name="osxkeychain"',
            '  else',
            '    helper_name="pass"',
            '  fi',
            'fi',
            'helper_filename="docker-credential-${helper_name}"',
            'BIN_PATH="/usr/local/bin"',
            '  RELEASE_TAG=$(curl -Ls --fail --retry 3 -o /dev/null -w "%<url_effective>s" ' \
            'https://github.com/docker/docker-credential-helpers/releases/latest | sed "s:.*/::")',
            'if [ -n "${release_tag}" ]; then',
            '  RELEASE_TAG="${release_tag}"',
            'fi',
            'minor_version=$(echo "${RELEASE_TAG}" | cut -d. -f2)',
            'base_url="https://github.com/docker/docker-credential-helpers/releases/download/"',
            'download_base_url="${base_url}${RELEASE_TAG}/${helper_filename}-${RELEASE_TAG}"',
            'if [ "${minor_version}" -gt 6 ]; then',
            '  DOWNLOAD_URL="${download_base_url}.${platform}-${arch}"',
            'else',
            '  DOWNLOAD_URL="${download_base_url}-${arch}.tar.gz"',
            'fi',
            'echo "Downloading from URL: ${DOWNLOAD_URL}"',
            'curl -L -o "${helper_filename}_archive" "${DOWNLOAD_URL}"',
            'if [ "${minor_version}" -le 6 ]; then',
            '  tar xvf "${helper_filename}_archive"',
            '  rm "${helper_filename}_archive"',
            'else',
            '  mv "${helper_filename}_archive" "${helper_filename}"',
            'fi',
            'chmod +x "${helper_filename}"',
            'mv "${helper_filename}" "${BIN_PATH}/${helper_filename}"'
          ]
        end
      end
    end
  end
end
