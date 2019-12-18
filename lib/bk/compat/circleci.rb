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
          elsif docker.length > 1
            docker_compose_services = {
              # This is a dummy container which does nothing but provide a
              # network stack for all the other containers to inherit so they
              # can share a localhost and see each others ports.
              #
              # It's host-networking without the host.
              "network" => {
                "image" => "ubuntu",
                "command" => "sleep infinity",
              },
            }

            docker.each.with_index do |d, i|
              d = d.dup

              image = d.delete("image")

              # The first docker container is the primary container and is
              # special - this is where commands will be run
              name = if i == 0
                       "primary"
                     else
                       image.gsub(/[^a-z0-9]/, "_")
                     end

              docker_compose_services[name] = t = {
                "image" => image,

                # Inherit the networkign stack of the dummy network container
                "network_mode" => "service:network",
              }

              # `ports` isn't actually supported and doesn't mean anything.
              d.delete("ports")

              if env = d.delete("environment")
                t["environment"] = env
              end

              if i == 0
                t["volumes"] = [".:/buildkite-checkout"]
              end

              unless d.empty?
                raise "Not sure what to do with these docker keys: #{d.keys.inspect}"
              end
            end

            docker_compose_config = {
              "version" => "3.6" ,
              "services" => docker_compose_services
            }

            bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
              path: "keithpitt/write-file#v0.1",
              config: {
                path: ".buildkite-compat-docker-compose.yml",
                contents: docker_compose_config.to_yaml
              }
            )

            bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
              path: "docker-compose#v3.1.0",
              config: {
                config: ".buildkite-compat-docker-compose.yml",
                run: "primary"
              }
            )
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
          else
            return [
              "echo '~~~ :circleci: #{action}'",
              "echo '⚠️ Not support yet'"
            ]
          end
        else
          "echo #{step.inspect}"
        end
      end
    end
  end
end
