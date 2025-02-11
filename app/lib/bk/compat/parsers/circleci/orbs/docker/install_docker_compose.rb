# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker installation commands
      class DockerOrb
        def translate_docker_install_docker_compose(config)
          install_dir = config.fetch('install-dir', '/usr/local/bin')
          version = config.fetch('version', 'latest')
          [
            '# Instead of installing docker-compose in a step, ' \
            'we recommend your agent environment to have it pre-installed',
            "echo '~~~ Installing docker-compose'",
            (install_dir == '/usr/local/bin' ? [] : ["mkdir -p #{install_dir}"]),
            install_docker_compose_commands(version, install_dir)
          ].flatten.compact
        end

        private

        def install_docker_compose_commands(_version, install_dir)
          [
            "PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')",
            "SYS_ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')",
            'SYS_ARCH="${SYS_ARCH/arm64/aarch64}"',
            'if [ "$version" = "latest" ]; then',
            '  RELEASE_PATH="latest/"',
            'else',
            '  RELEASE_PATH="download/${version}/"',
            'fi',
            'BINARY_URL="https://github.com/docker/compose/releases/${RELEASE_PATH}docker-compose-${PLATFORM}-${SYS_ARCH}"',
            "curl -L \"${BINARY_URL}\" -o #{install_dir}/docker-compose",
            "chmod +x #{install_dir}/docker-compose"
          ]
        end
      end
    end
  end
end
