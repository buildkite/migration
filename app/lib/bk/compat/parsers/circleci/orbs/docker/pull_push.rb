# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker/pull and docker/push commands
      class DockerOrb
        def translate_docker_pull(config)
          images = config.fetch('images', '').split(',').map(&:strip)
          return ['# No images provided to pull.'] if images.empty?

          ignore_error = config['ignore-docker-pull-error'] ? ' || true' : ''
          images.map { |image| "docker pull #{image}#{ignore_error}" }
        end

        def translate_docker_push(config)
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
