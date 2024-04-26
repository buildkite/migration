# frozen_string_literal: true

require_relative '../../pipeline/step'
require_relative '../../pipeline/plugin'

module BK
  module Compat
    module BitBucketSteps
      # Implementation of image-related key translations
      class Step
        def load_caches!
          @caches = {
            'docker' => cache_docker,
            'composer' => cache_composer,
            'dotnetcore' => cache_dotnetcore,
            'gradle' => cache_gradle,
            'ivy2' => cache_ivy2,
            'maven' => cache_maven,
            'node' => cache_node,
            'pip' => cache_pip,
            'sbt' => cache_sbt
          }
        end

        def translate_caches(caches)
          return [] if caches.nil? || caches.empty?

          BK::Compat::CommandStep.new.tap do |cmd|
            cmd.add_commands('# caching works differently (invalidations have to be explicit)')
            caches.map do |c|
              cmd << @caches&.fetch(c, ["# cache #{c} currently not supported"])
            end
          end
        end

        def cache_docker
          [
            '# docker layer caching is best implemented by docker',
            '# Use BUILDKIT_INLINE_CACHE when building/pushing images and then --cache-from IMAGE'
          ]
        end

        def cache_composer
          file_plugin('composer.json', '~/.composer/cache')
        end

        def cache_dotnetcore
          file_plugin('packages.config', '~/.nuget/packages')
        end

        def cache_gradle
          file_plugin('settings.gradle', '~/.gradle/caches')
        end

        def cache_ivy2
          file_plugin('ivy.xml', '~/.ivy2/cache')
        end

        def cache_maven
          file_plugin('pom.xml', '~/.m2/repository')
        end

        def cache_node
          file_plugin('packages.json', 'node_modules')
        end

        def cache_pip
          file_plugin('requirements.txt', '~/.cache/pip')
        end

        def cache_sbt
          file_plugin('build.sbt', '~/.sbt')
        end

        def file_plugin(file, path)
          BK::Compat::Plugin.new(
            name: 'cache',
            config: {
              manifest: file,
              path: path,
              restore: 'file',
              save: 'file'
            }
          )
        end
      end
    end
  end
end
