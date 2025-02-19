# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker installation commands
      class DockerOrb
        def translate_docker_install_dockerize(config)
          install_dir = config.fetch('install-dir', config.fetch('dockerize-install-dir', '/usr/local/bin'))
          version = config.fetch('version', 'latest')
          [
            '# Instead of installing dockerize in a step, ',
            '# we recommend your agent environment to have it pre-installed',
            "echo '~~~ Installing Dockerize'",
            (install_dir == '/usr/local/bin' ? [] : ["mkdir -p #{install_dir}"]),
            install_dockerize_commands(version, install_dir)
          ].flatten.compact
        end

        private

        def install_dockerize_commands(version, install_dir)
          [
            'PLATFORM=""',
            'if [ "$(uname -s)" = "Darwin" ]; then',
            "  PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')",
            'else',
            "SYS_ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')",
            '  case "$SYS_ARCH" in',
            '    "x86_64") SYS_ARCH="amd64" ;;',
            '    "aarch64") SYS_ARCH="arm64" ;;',
            '  esac',
            '',
            '  if [ -f /etc/issue ] && grep -q "Alpine" /etc/issue; then',
            '    PLATFORM="alpine-linux-amd64"',
            '  else',
            '    PLATFORM="linux-${SYS_ARCH}"',
            '  fi',
            'fi',
            '',
            'BINARY_URL=""',
            "version=\"#{version}\"",
            'if [ "$version" = "latest" ]; then',
            '  BINARY_URL="https://github.com/jwilder/dockerize/releases/latest/download/dockerize-${PLATFORM}.tar.gz"',
            'else',
            '  BINARY_URL="https://github.com/jwilder/dockerize/releases/download/${version}/dockerize-${PLATFORM}-${version}.tar.gz"',
            'fi',
            "curl -L \"${BINARY_URL}\" -o 'dockerize.tar.gz'",
            'tar xf dockerize.tar.gz',
            'rm -f dockerize.tar.gz',
            "mv dockerize #{install_dir}",
            "chmod +x #{install_dir}/dockerize"
          ]
        end
      end
    end
  end
end
