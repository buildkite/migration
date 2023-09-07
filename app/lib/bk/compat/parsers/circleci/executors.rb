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
          plugin_config = {}.tap do |pgc|
            pgc['image'] = config['image']
            pgc['hostname'] = config['name'] if config.include?('name')
            pgc['entrypoint'] = config['entrypoint'] if config.include?('entrypoint')
            pgc['user'] = config['user'] if config.include?('user')

            # TODO: use translate_run instead for this
            pgc['command'] = config['command'] if config.include?('command')
            pgc['environment'] = config['environment'] if config.include?('environment')
          end
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
            step.plugins << BK::Compat::Plugin.new(
              name: 'ecr',
              config: {
                'login' => true,
                'account-ids': config['image'].match(/^(\d+)\./)[1]
              }
            )
            # TODO: handle OIDC or AWS credentials
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
