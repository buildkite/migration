module BK
  module Compat
    class CircleCI
      require "yaml"

      def self.parse_file(file_path)
        new(YAML.load_file(file_path)).parse
      end

      def initialize(config)
        @config = config
      end

      def parse
        bk_pipeline = Pipeline.new

        @config.fetch("jobs").each do |(key, job)|
          bk_step = BK::Compat::Pipeline::Step.new(key: key, label: key)

          job.fetch("steps").each do |circle_step|
            [*transform_circle_step_to_commands(circle_step)].each do |s|
              bk_step.commands << s if s
            end
          end

          # bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
          #   path: "thedyrt/skip-checkout#v0.1.1"
          # )

          docker = job.fetch("docker")
          if docker.length == 1
            image = docker.first.fetch("image")

            bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
              path: "docker#v3.3.0",
              config: {
                image: image,
                workdir: "/buildkite-checkout"
              }
            )
          else
            raise "Dunno how to docker with #{docker.length} defined"
          end

          bk_pipeline.steps << bk_step
        end

        bk_pipeline
      end

      private

      def transform_circle_step_to_commands(step)
        if step == "checkout"
          return [
            "echo '--- :circleci: checkout'",
            "echo '$ sudo cp -R /buildkite-checkout /home/circleci/checkout'",
            "sudo cp -R /buildkite-checkout /home/circleci/checkout",

            "echo '$ sudo chown -R circleci:circleci /home/circleci/checkout'",
            "sudo chown -R circleci:circleci /home/circleci/checkout",

            "echo '$ cd /home/circleci/checkout'",
            "cd /home/circleci/checkout"
          ]
        end

        if step.is_a?(Hash)
          action = step.keys.first
          config = step[action]

          case action
          when "run"
            if config.is_a?(Hash)
              env_prefix = []
              if env = config["environment"]
                env.each do |(key, value)|
                  env_prefix << "#{key}=#{value.inspect}"
                end
              end

              command = if env_prefix.any?
                          env_prefix.join(" ") + " " + config.fetch("command")
                        else
                          config.fetch("command")
                        end

              if name = config["name"]
                "echo #{"--- #{name}".inspect}\n#{command}"
              else
                command
              end
            else
              config
            end
          when "restore_cache"
            return [
              "echo '--- :circleci: restore_cache'",
              "echo '⚠️ Not support yet'"
            ]
          when "save_cache"
            return [
              "echo '--- :circleci: save_cache'",
              "echo '⚠️ Not support yet'"
            ]
          else

            "echo #{"???? #{action} ????".inspect}"
          end
        else
          "echo #{step.inspect}"
        end
      end
    end
  end
end
