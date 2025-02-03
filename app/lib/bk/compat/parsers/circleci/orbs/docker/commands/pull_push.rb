# frozen_string_literal: true

module BK
  module Compat
    class Parsers
      module CircleCI
        module Orbs
          module Docker
            # Handles docker pull and push commands for CircleCI orb
            module Commands
              module_function

              def pull_docker(config)
                images = config.fetch('images', '').split(',').map(&:strip)
                return ['# No images provided to pull.'] if images.empty?

                ignore_error = config['ignore-docker-pull-error'] ? ' || true' : ''
                images.map { |image| "docker pull #{image}#{ignore_error}" }
              end

              def push_docker(config)
                full_image = config.fetch('image') { raise 'Image name must be provided' }
                full_image = "#{config['registry']}/#{full_image}" if config['registry']
                tags = config.fetch('tag', '').split(',').map(&:strip)
                [
                  *tags.map { |tag| "docker push #{full_image}:#{tag}" },
                  ("mkdir -p #{File.dirname(config['digest-path'])}" if config['digest-path']),
                  (if config['digest-path']
                     "docker image inspect --format '{{index .RepoDigests 0}}' " \
                       "#{full_image}:#{tags.first} > #{config['digest-path']}"
                   end)
                ].compact
              end
            end
          end
        end
      end
    end
  end
end
