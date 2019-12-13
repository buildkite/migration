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

          docker = job.fetch("docker")
          if docker.length == 1
            image = docker.first.fetch("image")

            bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
              path: "docker#v3.3.0",
              config: { "image" => image }
            )
          else
            p docker
            raise "More than 1 docker"
          end

          bk_pipeline.steps << bk_step
        end

        bk_pipeline
      end

      private

      def transform_circle_step_to_commands(step)
        return if step == "checkout"

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

              if env_prefix.any?
                env_prefix.join(" ") + " " + config.fetch("command")
              else
                config.fetch("command")
              end
            else
              config
            end
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
