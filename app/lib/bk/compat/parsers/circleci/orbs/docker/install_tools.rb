# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker installation commands
      class DockerOrb
        def translate_docker_install_docker(config)
          install_dir = config.fetch('install-dir', '/usr/local/bin')
          version = config.fetch('version', 'latest')
          [
            '# Instead of installing docker in a step, we recommend your agent environment to have it pre-installed',
            "echo '~~~ Installing Docker'",
            install_docker_commands(version, install_dir)
          ].flatten.compact
        end

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

        def translate_docker_install_dockerize(config)
          install_dir = config.fetch('install-dir', '/usr/local/bin')
          version = config.fetch('version', 'latest')
          [
            '# Instead of installing dockerize in a step, we recommend your agent environment to have it pre-installed',
            "echo '~~~ Installing Dockerize'",
            (install_dir == '/usr/local/bin' ? [] : ["mkdir -p #{install_dir}"]),
            install_dockerize_commands(version, install_dir)
          ].flatten.compact
        end

        private

        def install_docker_commands(version, install_dir)
          if version == 'latest'
            ['curl -fsSL https://get.docker.com -o get-docker.sh', 'sh get-docker.sh']
          else
            [(install_dir == '/usr/local/bin' ? [] : ["mkdir -p #{install_dir}"]),
             "VERSION=#{version}",
             'curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${VERSION}.tgz -o docker.tgz',
             'tar xzvf docker.tgz',
             "cp docker/* #{install_dir}/",
             'rm -rf docker docker.tgz']
          end
        end

        def install_docker_compose_commands(_version, install_dir)
          [
            "PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')",
            "SYS_ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')",
            'if [ "$SYS_ARCH" = "arm64" ]; then SYS_ARCH="aarch64"; fi',
            'RELEASE_PATH="latest/"',
            'if [ "$version" != "latest" ]; then', '  RELEASE_PATH="download/${version}/"', 'fi',
            'BINARY_URL="https://github.com/docker/compose/releases/${RELEASE_PATH}docker-compose-${PLATFORM}-${SYS_ARCH}"',
            "curl -L \"${BINARY_URL}\" -o #{install_dir}/docker-compose",
            "chmod +x #{install_dir}/docker-compose"
          ]
        end

        def install_dockerize_commands(_version, install_dir)
          ['PLATFORM=""',
           'if [ "$(uname -s)" = "Darwin" ]; then', '  PLATFORM="darwin-amd64"',
           'else',
           '  SYS_ARCH=$(uname -m)',
           '  case "$SYS_ARCH" in',
           '    "x86_64") SYS_ARCH="amd64" ;;',
           '    "aarch64") SYS_ARCH="arm64" ;;',
           '  esac',
           '  if [ -f /etc/issue ] && grep -q "Alpine" /etc/issue; then',
           '    PLATFORM="alpine-linux-amd64"',
           '  else', '    PLATFORM="linux-${SYS_ARCH}"', '  fi',
           'fi',
           'BINARY_URL=""',
           'if [ "$version" = "latest" ]; then',
           '  BINARY_URL="https://github.com/jwilder/dockerize/releases/latest/download/dockerize-${PLATFORM}.tar.gz"',
           'else',
           '  BINARY_URL="https://github.com/jwilder/dockerize/releases/download/${version}/dockerize-${PLATFORM}-${version}.tar.gz"',
           'fi',
           "curl -L \"${BINARY_URL}\" -o 'dockerize.tar.gz'",
           'tar xf dockerize.tar.gz',
           'rm -f dockerize.tar.gz',
           "mv dockerize #{install_dir}",
           "chmod +x #{install_dir}/dockerize"]
        end

        def determine_dockerize_platform
          return 'darwin-amd64' if `uname -s`.strip == 'Darwin'

          sys_arch = { 'x86_64' => 'amd64', 'aarch64' => 'arm64' }.fetch(`uname -m`.strip, `uname -m`.strip)
          alpine? ? 'alpine-linux-amd64' : "linux-#{sys_arch}"
        end

        def alpine?
          File.exist?('/etc/issue') && File.read('/etc/issue').include?('Alpine')
        end
      end
    end
  end
end
