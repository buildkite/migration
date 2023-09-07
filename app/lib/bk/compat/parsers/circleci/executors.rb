# frozen_string_literal: true

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def load_executor(name, config)
        raise 'Duplicate executor name' if @executors.include?(name)

        type, ex_conf = get_executor(config)
        raise "Invalid executor configuration #{config}" if key.nil?

        @executors[name] = BK::Compat::CommandStep.new(key: "Executor #{type}").tap do |step|
          step.env = config.fetch('environment', {})
          step.commands << "cd #{config['working_directory']}" if config.include?('working_directory')
          step.commands << '# shell should be configured in the agent' if config.include?('shell')
          step.agents['resource_class'] = config['resource_class'] if config.include?('resource_class')
          step << parse_executor(type, ex_conf)
        end
      end

      def get_executor(config)
        existing = config.slice('docker', 'machine', 'macos', 'windows')

        # only one of these must exist
        key = existing.length != 1 ? nil : existing.keys.first
        # Hash[nil] == nil :)
        [key, config[key]]
      end

      def parse_executor(type, config)
        send("executor_#{type}", config)
      end

      def executor_docker(config)
        raise 'Need to use Docker Compose for this :(' if config.length > 1

        # assume we have a single configuration
        config = config[0]

        BK::Compat::CommandStep.new.tap do |step|
          step.agents['executor_type'] = 'docker'
          plugin_config = config.slice('image', 'entrypoint', 'user', 'command', 'environment')
          plugin_config['add-host'] = "${config['name']}:127.0.0.1" if config.include?('name')

          step.plugins << BK::Compat::Plugin.new(
            name: 'docker',
            config: plugin_config
          )

          if config.include?('auth')
            step.plugins << BK::Compat::Plugin.new(
              name: 'docker-login',
              config: {
                'username' => config['auth']['username'],
                'password-env' => config['auth']['password'].ltrim('$')
              }
            )
          end

          if config.include?('aws-auth')
            url_regex = '^(?:[^/]+//)?(\d+).dkr.ecr.([^.]+).amazonaws.com'
            account_id, region = config['image'].match(url_regex).captures
            cfg = {
              'login' => true,
              'account-ids' => account_id,
              'region' => region
            }

            cfg['assume-role'] = {'role-arn' => config['oidc_role_arn']} if config.include?('oidc_role_arn')

            step.plugins << BK::Compat::Plugin.new(
              name: 'ecr',
              config: cfg
            )

            if cfg['aws-auth'].include('aws_access_key_id')
              step.commands << '# Configure the agent to have the appropriate credentials for ECR auth'
            end
          end
        end
      end

      def executor_machine(config)
        BK::Compat::CommandStep.new.tap do |step|
          step.agents['executor_type'] = 'machine'
          step.agents['executor_image'] = config['image']
          if config.include?('docker_layer_caching')
            step.commands << '# Docker Layer Caching should be configured in the agent'
          end
        end
      end

      def executor_macos(config)
        BK::Compat::CommandStep.new.tap do |step|
          step.agents['executor_type'] = 'osx'
          step.agents['executor_xcode'] = config['xcode']
        end
      end

      def executor_windows(_config)
        BK::Compat::CommandStep.new.tap do |step|
          step.agents['executor_type'] = 'windows'
        end
      end
    end
  end
end
