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
            sources.each do |s|
              ppa = "ppa:#{s}"
              script << "add-apt-repository #{s.inspect}"
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
            script << cmd
          end
        end

        script << @config.fetch("script")

        @config.fetch("rvm").each do |rvm|
          bk_step = BK::Compat::Pipeline::CommandStep.new(
            label: ":travisci: #{rvm}",
            commands: script
          )

          if soft_fails.include?(rvm)
            bk_step.soft_fail = true
          end

          bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
            path: "docker#v3.3.0",
            config: {
              image: "ruby:#{rvm}",
              workdir: "/buildkite-checkout"
            }
          )

          bk_pipeline.steps << bk_step
        end

        bk_pipeline
      end

    end
  end
end
