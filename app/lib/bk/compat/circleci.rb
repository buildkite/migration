# frozen_string_literal: true

require_relative 'pipeline'

module BK
  module Compat
    # CircleCI translation scaffolding
    class CircleCI
      require 'yaml'

      def self.name
        'Circle CI'
      end

      def self.matches?(text)
        keys = YAML.safe_load(text, aliases: true).keys
        keys.include?('version') && keys.include?('jobs')
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text, aliases: true)
        @now = Time.now
        @options = options
      end

      def parse
        bk_pipeline = Pipeline.new

        steps_by_key = @config.fetch('jobs').each_with_object({}) do |(key, job), hash|
          bk_step = BK::Compat::Pipeline::CommandStep.new(key: key, label: ":circleci: #{key}")

          job.fetch('steps').each do |circle_step|
            [*transform_circle_step_to_commands(circle_step)].each do |s|
              bk_step.commands << s if s
            end
          end

          # Figure out which executor to use
          executors = job.slice('docker')
          if executors.length > 1
            raise "More than 1 executor found (#{executors.keys.length.inspect})"
          elsif executors.length == 1
            executor_name = executors.keys.first
            executor_config = executors.values.first

            case executor_name
            when 'docker'
              setup_docker_executor(bk_step, executor_config)
            else
              raise "Unsupported executor #{executor_name}"
            end
          end

          hash[key] = bk_step
        end

        if @config.has_key?('workflows')
          workflows = @config.fetch('workflows')
          version = workflows.delete('version')

          # Turn each work flow into a step group
          bk_groups = workflows.map do |(workflow_name, workflow_config)|
            bk_steps = workflow_config.fetch('jobs').map do |j|
              case j
              when String
                steps_by_key.fetch(j)
              when Hash
                key = j.keys.first
                step = steps_by_key.fetch(key).dup

                if requires = j[key]['requires']
                  step.depends_on = [*requires]
                end

                step
              else
                raise "Dunno what #{j.inspect} is"
              end
            end

            Pipeline::GroupStep.new(
              label: ":circleci: #{workflow_name}",
              key: workflow_name,
              steps: bk_steps
            )
          end

          # If there ended up being only 1 workflow, skip the group and just
          # pull the steps out. If there were multiple groups, make sure
          # they're all part of the pipeline.
          if bk_groups.length == 1
            bk_pipeline.steps = bk_pipeline.steps.concat(bk_groups.first.steps)
          elsif bk_groups.length > 1
            bk_pipeline.steps = bk_pipeline.steps.concat(bk_groups)
          end
        else
          # If no workflow is defined, it's expected that there's a `build` job
          # defined
          bk_pipeline.steps << steps_by_key.fetch('build')
        end

        bk_pipeline
      end

      private

      def setup_docker_executor(bk_step, executor_config)
        if executor_config.length == 1
          image = executor_config.first.fetch('image')

          bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
            path: 'docker#v3.3.0',
            config: {
              image: image,
              workdir: '/buildkite-checkout'
            }
          )
        elsif executor_config.length > 1
          docker_logins = []
          ecr_logins = []

          docker_compose_services = {
            # This is a dummy container which does nothing but provide a
            # network stack for all the other containers to inherit so they
            # can share a localhost and see each others ports.
            #
            # It's host-networking without the host.
            'network' => {
              'image' => 'ubuntu',
              'command' => 'sleep infinity'
            }
          }

          executor_config.each.with_index do |d, i|
            # We'll be deleting config from it as we go, so get a copy of it so
            # we're not mutating the original value
            d = d.dup

            # First, let's get the image it'll be using
            image = d.delete('image')

            # The first docker container is the primary container and is
            # special - this is where commands will be run
            name = if i == 0
                     'primary'
                   else
                     image.gsub(/[^a-z0-9]/, '_')
                   end

            docker_compose_services[name] = t = {
              'image' => image,

              # Inherit the networkign stack of the dummy network container
              'network_mode' => 'service:network'
            }

            # `ports` isn't actually supported and doesn't mean anything.
            d.delete('ports')

            if env = d.delete('environment')
              t['environment'] = env
            end

            if entrypoint = d.delete('command')
              t['entrypoint'] = entrypoint
            end

            # Do we need a `docker login` for this image?
            if auth = d.delete('auth')
              login = {}

              if username = auth['username']
                login[:username] = username.chomp
              end

              if password = auth['password']
                chompped_password = password.chomp
                if chompped_password.start_with?('$')
                  login[:password_env] = chompped_password.sub(/\A\$/, '')
                else
                  login[:password] = chompped_password
                end
              end

              docker_logins << login unless login.empty?
            end

            # What about an ECR login?
            if aws_auth = d.delete('aws_auth')
              ecr_login = {
                # The account id is the first part of the image, so we'll exract that as well
                account_ids: image.match(/\A(\d+)\./)[1]
              }

              if access_key_id = aws_auth['aws_access_key_id']
                ecr_login[:access_key_id] = access_key_id.chomp
              end

              if secret_access_key = aws_auth['aws_secret_access_key']
                chompped_secret_access_key = secret_access_key.chomp
                raise 'AWS secret access key needs to be an env' unless chompped_secret_access_key.start_with?('$')

                ecr_login[:secret_access_key_env] = chompped_secret_access_key.sub(/\A\$/, '')

              end

              ecr_logins << ecr_login unless ecr_login.empty?
            end

            # We only want to mount the checkout in the primary container
            t['volumes'] = ['../:/buildkite-checkout'] if i == 0

            raise "Not sure what to do with these docker keys: #{d.keys.inspect}" unless d.empty?
          end

          # The primary container should depend on all the other containers
          # so they will be started before commands are run
          docker_compose_services['primary']['depends_on'] = docker_compose_services.keys - ['primary']

          docker_compose_config = {
            'version' => '3.6',
            'services' => docker_compose_services
          }

          docker_compose_filename = ".buildkite/#{@now.to_i}-#{bk_step.key}-docker-compose.yml"

          bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
            path: 'keithpitt/write-file#v0.2',
            config: {
              path: docker_compose_filename,
              contents: docker_compose_config.to_yaml
            }
          )

          if docker_logins.length > 0
            docker_logins.uniq.each do |login|
              bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
                path: 'docker-login#v2.0.1',
                config: login
              )
            end
          end

          if ecr_logins.length > 0
            ecr_logins.uniq.each do |ecr_auth|
              bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
                path: 'ecr#pass-through-creds',
                config: { login: true }.merge(ecr_auth)
              )
            end
          end

          bk_step.plugins << BK::Compat::Pipeline::Plugin.new(
            path: 'docker-compose#v3.1.0',
            config: {
              config: docker_compose_filename,
              run: 'primary'
            }
          )
        end
      end

      def transform_circle_step_to_commands(circle_step)
        if circle_step == 'checkout'
          return [
            "echo '~~~ :circleci: checkout'",
            'sudo cp -R /buildkite-checkout /home/circleci/checkout',
            'sudo chown -R circleci:circleci /home/circleci/checkout',
            'cd /home/circleci/checkout'
          ]
        end

        if circle_step.is_a?(Hash)
          action = circle_step.keys.first
          config = circle_step[action]

          case action
          when 'run'
            if config.is_a?(Hash)
              env_prefix = []
              if env = config['environment']
                env.each do |(key, value)|
                  env_prefix << "#{key}=#{value.inspect}"
                end
              end

              command = if env_prefix.any?
                          env_prefix.join(' ') + ' ' + config.fetch('command')
                        else
                          config.fetch('command')
                        end

              if name = config['name']
                [
                  "echo #{"--- #{name}".inspect}",
                  command
                ]
              else
                [
                  "echo '--- :circleci: run'",
                  command
                ]
              end
            else
              [
                "echo '--- :circleci: run'",
                config
              ]
            end
          when 'persist_to_workspace'
            root = config.fetch('root')

            [*config.fetch('paths')].map do |path|
              [
                "echo '~~~ :circleci: persist_to_workspace (path: #{path.inspect})'",
                'workspace_dir=$$(mktemp -d)',
                'sudo chown -R circleci:circleci $$workspace_dir',
                'mkdir $$workspace_dir/.workspace',
                'cp -R . $$workspace_dir/.workspace',
                'cd $$workspace_dir',
                "buildkite-agent artifact upload #{".workspace/#{path}".inspect}",
                'cd -'
              ]
            end.flatten
          when 'attach_workspace'
            at = config.fetch('at')
            [
              "echo '~~~ :circleci: attach_workspace (at: #{at.inspect})'",
              'workspace_dir=$$(mktemp -d)',
              'sudo chown -R circleci:circleci $$workspace_dir',
              'buildkite-agent artifact download ".workspace/*" $$workspace_dir',
              'mv $$workspace_dir/.workspace/* .'
            ].flatten
          when 'setup_remote_docker'
            [
              "echo '~~~ :circleci: #{action}'",
              "echo '⚠️ Your host docker is being used'"
            ]
          else
            [
              "echo '~~~ :circleci: #{action}'",
              "echo '⚠️ Not support yet'"
            ]
          end
        else
          "echo #{circle_step.inspect}"
        end
      end
    end
  end
end
