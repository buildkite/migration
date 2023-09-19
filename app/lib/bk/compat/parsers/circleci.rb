# frozen_string_literal: true

require_relative '../pipeline'
require_relative 'circleci/jobs'
require_relative 'circleci/steps'
require_relative 'circleci/translator'
require_relative 'circleci/workflows'

module BK
  module Compat
    # CircleCI translation scaffolding
    class CircleCI
      include StepTranslator
      require 'yaml'

      def self.name
        'Circle CI'
      end

      def self.option
        'circleci'
      end

      def self.matches?(text)
        keys = YAML.safe_load(text, aliases: true).keys
        mandatory_keys = %w[version jobs workflows].freeze
        keys & mandatory_keys == mandatory_keys
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text, aliases: true)
        @now = Time.now
        @options = options
        @steps_by_key = {}

        builtin_steps = BK::Compat::CircleCISteps::Builtins.new
        register_translator(*builtin_steps.register)
      end

      def parse
        bk_pipeline = Pipeline.new

        @config.fetch('jobs').each do |key, config|
          parse_job(key, config)
        end

        workflows = @config.fetch('workflows', {})
        workflows.delete('version')
        # Turn each work flow into a step group
        bk_groups = workflows.map { |wf, config| parse_workflow(wf, config) }

        if bk_groups.empty?
          # If no workflow is defined, it's expected that there's a `build` job
          bk_groups = [@steps_by_key.fetch('build')]
        elsif bk_groups.length == 1
          # If there ended up being only 1 workflow, skip the group and just
          # pull the steps out.
          bk_groups = bk_groups.first.steps
        end

        bk_pipeline.steps.concat(bk_groups)

        bk_pipeline
      end

      private

      def setup_docker_executor(bk_step, executor_config)
        if executor_config.length == 1
          image = executor_config.first.fetch('image')

          bk_step.plugins << BK::Compat::Plugin.new(
            name: 'docker',
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
            name = if i.zero?
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

            if (env = d.delete('environment'))
              t['environment'] = env
            end

            if (entrypoint = d.delete('command'))
              t['entrypoint'] = entrypoint
            end

            # Do we need a `docker login` for this image?
            if (auth = d.delete('auth'))
              login = {}

              if (username = auth['username'])
                login[:username] = username.chomp
              end

              if (password = auth['password'])
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
            if (aws_auth = d.delete('aws_auth'))
              ecr_login = {
                # The account id is the first part of the image, so we'll exract that as well
                account_ids: image.match(/\A(\d+)\./)[1]
              }

              if (access_key_id = aws_auth['aws_access_key_id'])
                ecr_login[:access_key_id] = access_key_id.chomp
              end

              if (secret_access_key = aws_auth['aws_secret_access_key'])
                chompped_secret_access_key = secret_access_key.chomp
                raise 'AWS secret access key needs to be an env' unless chompped_secret_access_key.start_with?('$')

                ecr_login[:secret_access_key_env] = chompped_secret_access_key.sub(/\A\$/, '')

              end

              ecr_logins << ecr_login unless ecr_login.empty?
            end

            # We only want to mount the checkout in the primary container
            t['volumes'] = ['../:/buildkite-checkout'] if i.zero?

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

          # TODO: remove this if possible
          bk_step.plugins << BK::Compat::Plugin.new(
            name: 'keithpitt/write-file',
            version: 'v0.2',
            config: {
              path: docker_compose_filename,
              contents: docker_compose_config.to_yaml
            }
          )

          unless docker_logins.empty?
            docker_logins.uniq.each do |login|
              bk_step.plugins << BK::Compat::Plugin.new(
                name: 'docker-login',
                config: login
              )
            end
          end

          unless ecr_logins.empty?
            ecr_logins.uniq.each do |ecr_auth|
              bk_step.plugins << BK::Compat::Plugin.new(
                name: 'ecr',
                version: 'pass-through-creds', # TODO: remove this branch
                config: { login: true }.merge(ecr_auth)
              )
            end
          end

          bk_step.plugins << BK::Compat::Plugin.new(
            name: 'docker-compose',
            config: {
              config: docker_compose_filename,
              run: 'primary'
            }
          )
        end
      end

      def transform_circle_step_to_commands(circle_step)
        if circle_step.is_a?(Hash)
          # TODO: make sure that a step is a single-key action
          action = circle_step.keys.first
          config = circle_step[action]
        else
          action = circle_step
          config = nil
        end

        translate_step(action, config)
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::CircleCI)
