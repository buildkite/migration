# frozen_string_literal: true

module BK
  module Compat
    class Parsers
      module CircleCI
        module Orbs
          module Docker
            # Handles docker installation commands for CircleCI orb
            module Commands
              module_function

              def install_docker(config)
                install_dir = config.fetch('install-dir', '/usr/local/bin')
                version = config.fetch('version', 'latest')
                [
                  '# Instead of installing docker in a step, we recommend your agent environment ' \
                  'to have it pre-installed',
                  "echo '~~~ Installing Docker'",
                  generate_install_commands(version, install_dir)
                ].flatten.compact
              end

              def generate_install_commands(version, install_dir)
                if version == 'latest'
                  [
                    'curl -fsSL https://get.docker.com -o get-docker.sh',
                    'sh get-docker.sh'
                  ]
                else
                  [
                    (install_dir == '/usr/local/bin' ? [] : ["mkdir -p #{install_dir}"]),
                    "VERSION=#{version}",
                    'curl -fsSL https://download.docker.com/linux/static/stable/x86_64/' \
                    'docker-${VERSION}.tgz -o docker.tgz',
                    'tar xzvf docker.tgz',
                    "cp docker/* #{install_dir}/",
                    'rm -rf docker docker.tgz'
                  ]
                end
              end
            end
          end
        end
      end
    end
  end
end
