module BK
  module Compat
    class TravisCI
      require "yaml"

      def self.name
        "Travis CI"
      end

      def self.matches?(text)
        keys = YAML.safe_load(text).keys
        keys.include?("language") || keys.include?("rvm")
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

        # Travis defaults to ruby
        language = @config.fetch("language", "ruby")

        # Parse out global, and matrix environment variables
        env = @config.dig("env")

        matrix_env, global_env = nil, nil

        if env.is_a?(Hash)
          if global_env = env.dig("global")
            bk_pipeline.env = BK::Compat::Environment.new(global_env)
          end

          matrix_env = parse_env_matrix(
            env.dig("matrix") || env.dig("jobs")
          )
        elsif env.is_a?(Array)
          matrix_env = parse_env_matrix(env)
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

        if @config.has_key?("jobs")
          configure_stages(bk_pipeline, script)

          return bk_pipeline
        end

        # Pull out any soft-fails we should know about
        soft_fails = []
        if allow_failures = @config.dig("matrix", "allow_failures")
          allow_failures.each do |fc|
            soft_fails << fc["rvm"]
          end
        end

        # Finally add the main script
        main_script = @config.fetch("script")
        if main_script.is_a?(Array)
          main_script = main_script.join(' && ')
        end
        script << double_escape_env(main_script)

        config_key = case language
                     when "go" then "go"
                     when "ruby" then "rvm"
                     when "rust" then "rust"
                     else
                       raise BK::Compat::Error::NotSupportedError.new("#{language.inspect} isn't supported yet")
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

          if !matrix_env || matrix_env.empty?
            bk_pipeline.steps << bk_step
          else
            matrix_env.each do |this_env|
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
        when "rust"
          case version
          when "stable"
            "rust:latest"
          when "beta"
            raise BK::Compat::Error::NotSupportedError.new("rust doesn't have a beta image")
          when "nightly"
            "rustlang/rust:nightly"
          else
            "rust:#{version}"
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

      def prepare_step(label: nil, commands:, env:, conditional: nil)
        BK::Compat::Pipeline::CommandStep.new(
          label: label,
          commands: commands,
          env: env,
          conditional: conditional
        )
      end

      def configure_stages(bk_pipeline, before_script)
        jobs = {}
        last_stage_name = nil
        if job_configs = @config.dig("jobs", "include")
          job_configs.each do |jc|
            name = jc.fetch("stage", "test")
            name = last_stage_name if name.nil?

            jobs[name] ||= []
            jobs[name] << jc

            last_stage_name = name
          end
        end

        stages = @config.fetch("stages", [ "test" ])

        case stages
        when String
        when Hash
        when Array
          stages.each.with_index do |stage, index|
            job_name = case stage
                       when String
                         stage
                       when Hash
                         stage.fetch("name")
                       else
                         raise BK::Compat::Error::NotSupportedError.new("A stage must either be a string or a hash")
                       end

            if job_name.nil? || job_name.chomp.empty?
              raise BK::Compat::Error::NotSupportedError.new("Couldn't find a job name in one of the stages")
            elsif !jobs.has_key?(job_name)
              raise BK::Compat::Error::NotSupportedError.new("Couldn't find a job with name #{job_name.inspect}")
            end

            these_steps = jobs[job_name].map do |j|
              prepare_step(
                commands: [*before_script, j["script"]],
                env: j["env"],
                label: j["name"]
              )
            end

            conditional = stage["if"] if stage.is_a?(Hash)

            if index > 0
              bk_pipeline.steps << Pipeline::WaitStep.new
            end

            bk_pipeline.steps << Pipeline::GroupStep.new(
              label: ":travisci: #{job_name.capitalize}",
              key: job_name,
              steps: these_steps,
              conditional: conditional
            )
          end
        else
          raise BK::Compat::Error::NotSupportedError.new("stages needs to be either a string, an array or a hash")
        end
      end
    end
  end
end
