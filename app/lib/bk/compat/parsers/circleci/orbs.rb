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
        def matcher(orb, _conf)
          orb.start_with?('docker/')
        end

        def translator(action, config)
          method_name = "translate_#{action.tr('/-', '_')}"
          return send(method_name, config) if respond_to?(method_name, true)

          unsupported_action(action)
        end

        private

        def translate_docker_install_docker(config)
          install_dir = config.fetch('install-dir', '/usr/local/bin')
          version = config.fetch('version', 'latest')

          [
            '# Instead of installing docker in a step, we recommend your agent environment to have it pre-installed',
            "echo '~~~ Installing Docker'",
            install_commands(version, install_dir)
          ].flatten.compact
        end

        def install_commands(version, install_dir)
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

        def unsupported_action(action)
          [
            "# Unsupported docker orb action: #{action}"
          ]
        end
      end
    end
  end
end
