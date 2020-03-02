module BK
  module Compat
    class TravsiCI
      require "yaml"

      def self.name
        "Travis CI"
      end

      def self.matches?(text)
        keys = YAML.safe_load(text).keys
        keys.include?("language")
      end

      def initialize(text)
        @config = YAML.safe_load(text)
      end

      SOURCES = {
        "ubuntu-toolchain-r-test" => "ppa:ubuntu-toolchain-r/test"
      }

      def parse
        bk_pipeline = Pipeline.new

        soft_fails = []
        if allow_failures = @config.dig("matrix", "allow_failures")
          allow_failures.each do |fc|
            soft_fails << fc["rvm"]
          end
        end

        script = []

        if apt = @config.dig("addons", "apt")
          if sources = apt["sources"]
            script << "apt-get update"
            script << "apt-get install -y software-properties-common"
            sources.each do |s|
              script << "add-apt-repository -y #{SOURCES.fetch(s)}"
            end
            script << "apt-get update"
          end

          if packages = apt["packages"]
            packages.each do |pkg|
              script << "apt-get -q -y install #{pkg.inspect}"
            end
          end
        end

        if before_install = @config["before_install"]
          [*before_install].each do |cmd|
            script << escape_travis_env(cmd)
          end
        end

        script << @config.fetch("script")

        @config.fetch("rvm").each do |rvm|
          docker_image = rvm_docker_image_name(rvm)

          if docker_image
            bk_step = BK::Compat::Pipeline::CommandStep.new(
              label: ":travisci: #{rvm}",
              commands: script,
              env: {
                TRAVIS_RUBY_VERSION: rvm
              }
            )

            if soft_fails.include?(rvm)
              bk_step.soft_fail = true
            end

            bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
              path: "docker#v3.3.0",
              config: {
                image: docker_image,
                workdir: "/buildkite-checkout"
              }
            )
          else
            bk_step = BK::Compat::Pipeline::CommandStep.new(
              label: ":travisci: #{rvm} (no docker image)",
              commands: "exit 1"
            )
          end

          bk_pipeline.steps << bk_step
        end

        bk_pipeline
      end

      def escape_travis_env(cmd)
        cmd.gsub(/\$TRAVIS_/, "$$TRAVIS_")
      end

      def rvm_docker_image_name(version)
        case version
        when "jruby-head"
          nil
        when /^jruby-(.+)/
          "jruby:#{$1}"
        when /^rbx-/
          nil
        when "ruby-head"
          "rubocophq:ruby-snapshot"
        else
          "ruby:#{version}"
        end
      end
    end
  end
end
