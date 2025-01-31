# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker/pull and docker/push commands
      class DockerPushPull
        def translate_docker_pull(config)
          images = config.fetch('images', '').split(',').map(&:strip)
          return ['# No images provided to pull.'] if images.empty?

          ignore_error = config['ignore-docker-pull-error'] ? ' || true' : ''
          images.map { |image| "docker pull #{image}#{ignore_error}" }
        end

        def translate_docker_push(config)
          full_image = build_image_name(config, fetch_image(config))
          tags = fetch_tags(config)

          [
            *tags.map { |tag| "docker push #{full_image}:#{tag}" },
            ("mkdir -p #{File.dirname(config['digest-path'])}" if config['digest-path']),
            (if config['digest-path']
               "docker image inspect --format '{{index .RepoDigests 0}}' " \
                 "#{full_image}:#{tags.first} > #{config['digest-path']}"
             end)
          ].compact
        end

        private

        def build_image_name(config, image)
          config['registry'] ? "#{config['registry']}/#{image}" : image
        end

        def fetch_image(config)
          config.fetch('image') { raise 'Image name must be provided' }
        end

        def fetch_tags(config)
          return [ENV['CIRCLE_SHA1']] if config['tag'].nil? && ENV['CIRCLE_SHA1']

          config.fetch('tag', '').split(',').map(&:strip).tap do |tags|
            raise 'Tag or CIRCLE_SHA1 must be provided' if tags.empty?
          end
        end
      end
    end
  end
end
