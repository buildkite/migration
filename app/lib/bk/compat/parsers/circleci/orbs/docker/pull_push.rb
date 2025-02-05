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
          raise 'Image name must be provided' unless config.include?('image')

          full_image = config.values_at('registry', 'image').compact.join('/')
          tags = config.fetch('tag', '').split(',').map(&:strip)
          digest_path = config['digest-path']
          [
            *tags.map { |tag| "docker push #{full_image}:#{tag}" },
            ("mkdir -p #{File.dirname(digest_path)}" if digest_path),
            (if digest_path
               "docker image inspect --format '{{index .RepoDigests 0}}' #{full_image}:#{tags.first} > #{digest_path}"
             end)
          ].compact
        end
      end
    end
  end
end
