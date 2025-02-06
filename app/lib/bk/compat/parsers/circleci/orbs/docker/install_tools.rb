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
            '# Instead of installing dockerize in a step, ' \
            'we recommend your agent environment to have it pre-installed',
            "echo '~~~ Installing Dockerize'",
            (install_dir == '/usr/local/bin' ? [] : ["mkdir -p #{install_dir}"]),
            install_dockerize_commands(version, install_dir)
          ].flatten.compact
        end

        private

        def install_docker_commands(version, install_dir)
          if version == 'latest'
            [
              'curl -fsSL https://get.docker.com -o get-docker.sh',
              'sh get-docker.sh'
            ]
          else
            [
              (install_dir == '/usr/local/bin' ? [] : ["mkdir -p #{install_dir}"]),
              "VERSION=#{version}",
              'curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${VERSION}.tgz -o docker.tgz',
              'tar xzvf docker.tgz',
              "cp docker/* #{install_dir}/",
              'rm -rf docker docker.tgz'
            ]
          end
        end

        def install_docker_compose_commands(version, install_dir)
          binary_url = 'https://github.com/docker/compose/releases/' \
                       "#{version == 'latest' ? 'latest/' : "download/#{version}/"}docker-compose-linux-x86_64"
          [
            "curl -L #{binary_url} -o #{install_dir}/docker-compose",
            "chmod +x #{install_dir}/docker-compose"
          ]
        end

        def install_dockerize_commands(version, install_dir)
          binary_url = if version == 'latest'
                         'https://github.com/jwilder/dockerize/releases/latest/download/dockerize-linux-amd64.tar.gz'
                       else
                         "https://github.com/jwilder/dockerize/releases/download/#{version}/dockerize-linux-amd64-#{version}.tar.gz"
                       end
          [
            "curl -L #{binary_url} -o 'dockerize-linux-amd64.tar.gz'",
            'tar xf dockerize-linux-amd64*.tar.gz',
            'rm -f dockerize-linux-amd64*.tar.gz',
            "mv dockerize #{install_dir}",
            "chmod +x #{install_dir}/dockerize"
          ]
        end
      end
    end
  end
end
