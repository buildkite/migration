module BK
  module Compat
    module CircleCISteps
      class DockerOrb
        def matcher(orb, _conf)
          orb.start_with?('docker/')
        end

        def translator(action, config)
          case action
          when 'docker/build'
            translate_docker_build(config)
          when 'docker/install'
            translate_docker_install(config)
          else
            ["# Unsupported docker orb action: #{action}"]
          end
        end

        private

        def translate_docker_build(config)
          [
            "docker build -t #{config['image']}:#{config['tag']} ."
          ]
        end

        def translate_docker_install(config)
          [
            "echo '~~~ Installing Docker'",
            "curl -fsSL https://get.docker.com -o get-docker.sh",
            "sh get-docker.sh"
          ]
        end
      end
    end
  end
end