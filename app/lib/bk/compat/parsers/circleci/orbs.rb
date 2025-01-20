# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Generic orb steps/jobs (that states it is not supported)
      class GenericOrb
        def initialize(key)
          @prefix = key
        end

        def matcher(orb, _conf)
          orb.start_with?("#{@prefix}/")
        end

        def translator(action, _config)
          [
            "# #{action} is part of orb #{@prefix} which is not supported and should be translated by hand"
          ]
        end
      end

      # Handles Docker installation logic
      class DockerInstaller
        DOCKER_INSTALL_PARAMS = {
          'install-dir' => {
            'type' => 'string',
            'description' => 'Directory in which to install Docker binaries',
            'default' => '/usr/local/bin'
          },
          'version' => {
            'type' => 'string',
            'description' => 'Version of Docker to install',
            'default' => 'latest'
          }
        }.freeze

        def initialize(config = {})
          @config = config
        end

        def custom_directory?
          return false unless @config.key?('install-dir')

          @config['install-dir'] != DOCKER_INSTALL_PARAMS['install-dir']['default']
        end

        def specific_version?
          return false unless @config.key?('version')

          @config['version'] != DOCKER_INSTALL_PARAMS['version']['default']
        end

        def install_commands
          return simple_install unless custom_directory? || specific_version?

          generate_advanced_install
        end

        private

        def simple_install
          [
            "echo '~~~ Installing Docker'",
            'curl -fsSL https://get.docker.com -o get-docker.sh',
            'sh get-docker.sh'
          ]
        end

        def generate_advanced_install
          [
            generate_script_header,
            generate_custom_dir_commands,
            generate_version_specific_commands
          ].flatten.compact
        end

        def generate_script_header
          [
            '#!/usr/bin/env bash',
            '',
            'if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi',
            ''
          ]
        end

        def generate_custom_dir_commands
          return unless custom_directory?

          [
            '# Creating custom installation directory',
            "$SUDO mkdir -p #{@config['install-dir']}",
            ''
          ]
        end

        def generate_version_specific_commands
          if specific_version?
            generate_specific_version_install
          else
            [
              'curl -fsSL https://get.docker.com -o get-docker.sh',
              'sh get-docker.sh'
            ]
          end
        end

        def generate_specific_version_install
          install_dir = @config['install-dir'] || DOCKER_INSTALL_PARAMS['install-dir']['default']
          [
            "# Installing specific Docker version: #{@config['version']}",
            "VERSION=#{@config['version']}",
            'curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${VERSION}.tgz -o docker.tgz',
            'tar xzvf docker.tgz',
            "$SUDO cp docker/* #{install_dir}/",
            'rm -rf docker docker.tgz',
            ''
          ]
        end
      end

      # Docker orb specific implementation
      class DockerOrb
        def initialize
          @config = {}
        end

        def matcher(orb, _conf)
          orb.start_with?('docker/')
        end

        def translator(action, config)
          @config = config
          method_map = {
            'docker/build' => -> { translate_docker_build(config) },
            'docker/install' => -> { translate_docker_install },
            'docker/install-docker' => -> { DockerInstaller.new(@config).install_commands }
          }
          method_map.fetch(action, -> { ["# Unsupported docker orb action: #{action}"] }).call
        end

        private

        def translate_docker_build(config)
          image_tag = "#{config['image']}:#{config['tag'] || 'latest'}"
          [
            '# No need to setup remote docker, use the host docker',
            "docker build -t #{image_tag} ."
          ]
        end

        def translate_docker_install
          [
            "echo '~~~ Installing Docker'",
            'curl -fsSL https://get.docker.com -o get-docker.sh',
            'sh get-docker.sh'
          ]
        end
      end
    end
  end
end
