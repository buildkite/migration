module BK
  module Compat
    class CircleCI
      require "yaml"

      def self.parse_file(file_path)
        new(YAML.load_file(file_path)).parse
      end

      def self.parse_text(text)
        new(YAML.safe_load(text)).parse
      end

      def initialize(config)
        @config = config
      end

      def parse
        bk_pipeline = Pipeline.new

        steps_by_key = @config.fetch("jobs").each_with_object({}) do |(key, job), hash|
          bk_step = BK::Compat::Pipeline::Step.new(key: key, label: ":circleci: #{key}")

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
              config: {
                image: image,
                workdir: "/buildkite-checkout"
              }
            )
          else
            raise "Dunno how to docker with #{docker.length} defined"
          end

          hash[key] = bk_step
        end

        if @config.has_key?("workflows")
          workflows = @config.fetch("workflows")
          version = workflows.delete("version")

          workflows.fetch(workflows.keys.first).fetch("jobs").each do |j|
            case j
            when String
              bk_pipeline.steps << steps_by_key.fetch(j)
            when Hash

              key = j.keys.first
              step = steps_by_key.fetch(key).dup

              if requires = j[key]["requires"]
                step.depends_on = [*requires]
              end

              bk_pipeline.steps << step

            else
              raise "Dunno what #{j.inspect} is"
            end
          end
        else
          # If no workflow is defined, it's expected that there's a `build` job
          # defined
          bk_pipeline.steps << steps_by_key.fetch("build")
        end

        bk_pipeline
      end

      private

      def transform_circle_step_to_commands(step)
        if step == "checkout"
          return [
            "echo '~~~ :circleci: checkout'",
            "sudo cp -R /buildkite-checkout /home/circleci/checkout",
            "sudo chown -R circleci:circleci /home/circleci/checkout",
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
                return [
                  "echo #{"--- #{name}".inspect}",
                  command
                ]
              else
                return [
                  "echo '--- :circleci: run'",
                  command
                ]
              end
            else
              return [
                "echo '--- :circleci: run'",
                config
              ]
            end
          when "persist_to_workspace"
            root = config.fetch("root")

            [*config.fetch("paths")].map do |path|
              [
                "echo '~~~ :circleci: persist_to_workspace (path: #{path.inspect})'",
                "workspace_dir=$$(mktemp -d)",
                "sudo chown -R circleci:circleci $$workspace_dir",
                "mkdir $$workspace_dir/.workspace",
                "cp -R . $$workspace_dir/.workspace",
                "cd $$workspace_dir",
                "buildkite-agent artifact upload #{".workspace/#{path}".inspect}",
                "cd -"
              ]
            end.flatten
          when "attach_workspace"
            at = config.fetch("at")
            return [
              "echo '~~~ :circleci: attach_workspace (at: #{at.inspect})'",
              "workspace_dir=$$(mktemp -d)",
              "sudo chown -R circleci:circleci $$workspace_dir",
              "buildkite-agent artifact download \".workspace/*\" $$workspace_dir",
              "mv $$workspace_dir/.workspace/* ."
            ].flatten
          when "restore_cache"
            return [
              "echo '~~~ :circleci: restore_cache'",
              "echo '⚠️ Not support yet'"
            ]
          when "save_cache"
            return [
              "echo '~~~ :circleci: save_cache'",
              "echo '⚠️ Not support yet'"
            ]
          when "store_artifacts"
            return [
              "echo '~~~ :circleci: store_artifacts'",
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
