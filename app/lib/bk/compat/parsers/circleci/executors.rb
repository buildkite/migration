# frozen_string_literal: true

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def load_executor(name, config)
        raise 'Duplicate executor name' if @executors.include?(name)

        type, ex_conf = get_executor(config)
        raise "Invalid executor configuration #{config}" if type.nil?

        @executors[name] = parse_executor(type, ex_conf)
      end

      def get_executor(config)
        existing = config.slice('docker', 'machine', 'macos', 'windows')

        # only one of these must exist
        key = existing.length == 1 ? existing.keys.first : nil
        elems = %w[environment resource_class shell working_directory]
        [key, config.slice(*elems).merge(config.fetch(key, {}))]
      end

      def parse_executor(type, exc_conf)
        return nil if type.nil?

        BK::Compat::CommandStep.new(
          key: "Executor #{type}",
          env: exc_conf.fetch(environment, {}),
          agents: exc_conf.slice('resource_class')
        ).tap do |step|
          step.commands << "cd #{exc_conf['workdir']}" if ex_conf.include?('workdir')
          step.commands << '# shell should be configured in the agent' if exc_conf.include?['shell']
          step << send("executor_#{type}", exc_conf)
        end
      end

      def executor_docker(config)
        raise 'Need to use Docker Compose for this :(' if config.length > 1

        # assume we have a single configuration
        config = config[0]

        BK::Compat::CommandStep.new.tap do |step|
          step.agents['executor_type'] = 'docker'
          step << executor_docker_plugin(config)
          step << executor_docker_auth_plugin(config.fetch('auth', {}))
          step << executor_docker_aws_auth(config['aws-auth']) if config.include?('aws-auth')
        end
      end

      def executor_docker_auth_plugin(auth_config)
        return [] if auth_config.empty?

        BK::Compat::Plugin.new(
          name: 'docker-login',
          config: {
            'username' => auth_config['username'],
            'password-env' => auth_config['password'].ltrim('$')
          }
        )
      end

      def executor_docker_aws_auth(config)
        BK::Compat::CommandStep.new.tap do |step|
          if config.include?('aws_access_key_id')
            step.commands << '# Configure the agent to have the appropriate credentials for ECR auth'
          end

          url_regex = '^(?:[^/]+//)?(\d+).dkr.ecr.([^.]+).amazonaws.com'
          account_id, region = config['image'].match(url_regex).captures
          cfg = {
            'login' => true,
            'account-ids' => account_id,
            'region' => region
          }

          cfg['assume-role'] = { 'role-arn' => config['oidc_role_arn'] } if config.include?('oidc_role_arn')

          step << BK::Compat::Plugin.new(name: 'ecr', config: cfg)
        end
      end

      def executor_docker_plugin(config)
        plugin_config = config.slice('image', 'entrypoint', 'user', 'command', 'environment')
        plugin_config['add-host'] = "${config['name']}:127.0.0.1" if config.include?('name')

        BK::Compat::Plugin.new(
          name: 'docker',
          config: plugin_config
        )
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
