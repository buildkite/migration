module BK
  module Compat
    class TravisCI
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
      }

      IGNORE_SOURCES = [
        "ubuntu-toolchain-r-test"
      ]

      def parse
        bk_pipeline = Pipeline.new
        language = @config.fetch("language")

        # Parse out global travis environment variables
        if global_env = @config.dig("env", "global")
          bk_pipeline.env = BK::Compat::Environment.new(global_env)
        end

        # Pull out any soft-fails we should know about
        soft_fails = []
        if allow_failures = @config.dig("matrix", "allow_failures")
          allow_failures.each do |fc|
            soft_fails << fc["rvm"]
          end
        end

        script = []

        if apt = @config.dig("addons", "apt")
          script << "apt-get update"

          if sources = apt["sources"]
            sources_to_add = sources.map do |s|
              next if IGNORE_SOURCES.include?(s)
              "add-apt-repository -y #{SOURCES.fetch(s)}"
            end.compact

            if sources_to_add.any?
            script << "apt-get install -y software-properties-common"
            sources_to_add.each { |s| script << s }
            script << "apt-get update"
            end
          end

          if packages = apt["packages"]
            packages.each do |pkg|
              script << "apt-get -q -y install #{pkg.inspect}"
            end
          end
        end

        # Include `before_install` hooks
        if before_install = @config["before_install"]
          [*before_install].each do |cmd|
            script << double_escape_env(cmd)
          end
        end

        # Include `before_script` hooks
        if before_script = @config["before_script"]
          [*before_script].each do |cmd|
            script << double_escape_env(cmd)
          end
        end

        env_matrix = parse_env_matrix(
          @config.dig("env", "matrix") || @config.dig("env", "jobs")
        )

        # Finally add the main script
        script << double_escape_env(@config.fetch("script"))

        config_key = case language
                     when "go" then "go"
                     when "ruby" then "rvm"
                     else
                       BK::Compat::Error::NotSupportedError.new("#{language.inspect} isn't supported yet")
                     end

        [*@config.fetch(config_key)].each do |version|
          docker_image = docker_image_name(language, version)

          language_env_key = "TRAVIS_#{language.upcase}_VERSION"

          if docker_image
            bk_step = BK::Compat::Pipeline::CommandStep.new(
              label: ":travisci: #{language} #{version}",
              commands: script,
              env: {
                "#{language_env_key}": version
              }
            )

            if soft_fails.include?(version)
              bk_step.soft_fail = true
            end

            bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
              path: "keithpitt/compat-env#v0.1",
              config: {
                travisci: true
              }
            )

            bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
              path: "docker#v3.3.0",
              config: {
                image: docker_image,
                workdir: "/buildkite-checkout",
                "propagate-environment": true
              }
            )
          else
            bk_step = BK::Compat::Pipeline::CommandStep.new(
              label: ":travisci: #{version} (no docker image)",
              commands: "exit 1"
            )
          end

          if !env_matrix || env_matrix.empty?
            bk_pipeline.steps << bk_step
          else
            env_matrix.each do |this_env|
              duped_bk_step = bk_step.dup
              duped_bk_step.label = "#{duped_bk_step.label} (#{this_env.to_s})"
              duped_bk_step.env = this_env.merge(duped_bk_step.env)

              bk_pipeline.steps << duped_bk_step
            end
          end
        end

        bk_pipeline
      end

      def double_escape_env(cmd)
        cmd.gsub(/\$([A-Z])/, '$$\1')
      end

      def docker_image_name(language, version)
        case language
        when "go"
          "golang:#{version.sub(/\.x$/, "")}"
        when "ruby"
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

      def parse_env_matrix(env)
        return nil if env.nil?

        if env.is_a?(Array)
          env.map do |v|
            if v.is_a?(String)
              BK::Compat::Environment.new(double_escape_env(v))
            else
              raise BK::Compat::Error::NotSupportedError.new("Can't parse env.matrix as a non-string")
            end
          end
        else
          raise BK::Compat::Error::NotSupportedError.new("env.matrix needs to be an array")
        end
      end
    end
  end
end
