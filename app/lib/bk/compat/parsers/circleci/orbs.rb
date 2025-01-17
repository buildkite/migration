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

      # Docker orb specific implementation
      class DockerOrb
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

        def matcher(orb, _conf)
          orb.start_with?('docker/')
        end

        def translator(action, config)
          case action
          when 'docker/build'
            translate_docker_build(config)
          when 'docker/install'
            translate_docker_install
          when 'docker/install-docker'
            validate_and_translate_install_docker(config || {})
          when 'docker/push'
            translate_docker_push(config)
          else
            ["# Unsupported docker orb action: #{action}"]
          end
        end

        private

        def translate_docker_build(config)
          image_tag = "#{config['image']}:#{config['tag'] || 'latest'}"
          [
            "# No need to setup remote docker, use the host docker",
            "docker build -t #{image_tag} ."
          ]
        end

        def translate_docker_install
          [
            "echo '~~~ Installing Docker'",
            "curl -fsSL https://get.docker.com -o get-docker.sh",
            "sh get-docker.sh"
          ]
        end

        def validate_and_translate_install_docker(config)
          # Suggestion: Ensure Docker and necessary tools are pre-installed in the agent
          # If no special parameters are provided, use simple installation
          has_custom_dir = config.key?('install-dir') && config['install-dir'] != DOCKER_INSTALL_PARAMS['install-dir']['default']
          has_specific_version = config.key?('version') && config['version'] != DOCKER_INSTALL_PARAMS['version']['default']

          if !has_custom_dir && !has_specific_version
            return [
              "echo '~~~ Installing Docker'",
              "curl -fsSL https://get.docker.com -o get-docker.sh",
              "sh get-docker.sh"
            ]
          end

          # Advanced installation with custom parameters
          install_dir = config['install-dir'] || DOCKER_INSTALL_PARAMS['install-dir']['default']
          version = config['version'] || DOCKER_INSTALL_PARAMS['version']['default']
          
          commands = []
          commands << "#!/usr/bin/env bash"
          commands << ""
          commands << "if [[ $EUID == 0 ]]; then export SUDO=\"\"; else export SUDO=\"sudo\"; fi"
          commands << ""

          if has_custom_dir
            commands << "# Creating custom installation directory"
            commands << "$SUDO mkdir -p #{install_dir}"
            commands << ""
          end

          if has_specific_version
            commands << "# Installing specific Docker version: #{version}"
            commands << "VERSION=#{version}"
            commands << "curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${VERSION}.tgz -o docker.tgz"
            commands << "tar xzvf docker.tgz"
            commands << "$SUDO cp docker/* #{install_dir}/"
            commands << "rm -rf docker docker.tgz"
            commands << ""
          else
            commands << "curl -fsSL https://get.docker.com -o get-docker.sh"
            commands << "sh get-docker.sh"
          end

          commands
        end

        def translate_docker_push(config)
          image_tag = "#{config['image']}:#{config['tag'] || 'latest'}"
          [
            "docker push #{image_tag}"
          ]
        end
      end
    end
  end
end