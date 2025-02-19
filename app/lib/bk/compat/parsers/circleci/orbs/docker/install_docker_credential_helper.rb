# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker installation commands
      class DockerOrb
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
