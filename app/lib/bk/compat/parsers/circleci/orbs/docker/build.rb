# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the trasnlation of docker/build command
      class DockerBuild
        def translate_docker_build(config)
          [
            ('export DOCKER_BUILDKIT=1' if config['use-buildkit']),
            ("# Using BuildKit context at #{config['attach-at']}" if config['attach-at']),
            (if config['lint-dockerfile']
               '# Dockerlint is not supported at this time and should be translated by hand'
             end),
            *pull_cache_images(config),
            generate_build_command(config)
          ].compact
        end

        private

        def pull_cache_images(config)
          config.fetch('cache_from', '').split(',').map do |image|
            "docker pull #{image.strip} || true"
          end
        end

        def generate_build_command(config)
          [
            'docker',
            ('buildx' if config['cache_to']),
            'build',
            '-f', File.join(config.fetch('path', '.'), config.fetch('dockerfile', 'Dockerfile')),
            '-t', generate_tag(config),
            ("--build-context source=#{config['attach-at']}" if config['attach-at']),
            *generate_optional_args(config),
            config.fetch('docker-context', '.')
          ].compact.join(' ')
        end

        def generate_optional_args(config)
          [
            ("--cache-from=#{config['cache_from']}" if config['cache_from']),
            ("--cache-to=#{config['cache_to']}" if config['cache_to']),
            ('--load' if config['cache_to']),
            *config.fetch('extra_build_args', '').split.map(&:strip)
          ].compact
        end

        def generate_tag(config)
          registry = config.fetch('registry', 'docker.io')
          tag = config.fetch('tag', 'latest')
          tag.split(',').map { |t| "#{registry}/#{config['image']}:#{t.strip}" }.join(' -t ')
        end
      end
    end
  end
end
