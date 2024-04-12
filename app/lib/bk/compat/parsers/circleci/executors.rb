# frozen_string_literal: true

require_relative 'steps'

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def load_executor(name, config)
        raise 'Duplicate executor name' if @executors.include?(name)

        @executors[name] = parse_executor(**get_executor(config))
      end

      def get_executor(config)
        existing = config.slice('docker', 'machine', 'macos', 'windows')

        # only one of these must exist
        key = existing.length == 1 ? existing.keys.first : 'default'

        # standardize configuration
        elems = %w[environment resource_class shell working_directory]
        config.slice(*elems).tap do |cfg|
          cfg.transform_keys!(&:to_sym)
          cfg[:type] = key
          cfg[:conf] = config[key]
        end
      end

      def parse_executor(type: nil, conf: {}, working_directory: nil, shell: nil, resource_class: nil, environment: {})
        raise 'Invalid executor configuration' if type.nil?

        BK::Compat::CircleCISteps::CircleCIStep.new(
          key: "Executor #{type}",
          env: environment
        ).tap do |step|
          step.agents.merge!({ 'resource_class' => resource_class }) unless resource_class.nil?
          step.add_commands("cd #{working_directory}") unless working_directory.nil?
          step.add_commands('# shell should be configured in the agent') unless shell.nil?
          step << send("executor_#{type}", conf)
        end
      end

      def executor_docker(config)
        return 'Need to use Docker Compose for multiple image execution :(' if config.length > 1

        # assume we have a single configuration
        config = config[0]

        BK::Compat::CircleCISteps::CircleCIStep.new.tap do |step|
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
        return [] if config.empty?

        BK::Compat::CircleCISteps::CircleCIStep.new.tap do |step|
          if config.include?('aws_access_key_id')
            step.add_commands('# Configure the agent to have the appropriate credentials for ECR auth')
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
        config = { 'image' => 'self-hosted' } if config == true
        BK::Compat::CircleCISteps::CircleCIStep.new.tap do |step|
          step.agents['executor_type'] = 'machine'
          step.agents['executor_image'] = config['image']
          if config.include?('docker_layer_caching')
            step.add_commands('# Docker Layer Caching should be configured in the agent')
          end
        end
      end

      def executor_macos(config)
        BK::Compat::CircleCISteps::CircleCIStep.new.tap do |step|
          step.agents['executor_type'] = 'osx'
          step.agents['executor_xcode'] = config['xcode']
        end
      end

      def executor_windows(_config)
        BK::Compat::CircleCISteps::CircleCIStep.new.tap do |step|
          step.agents['executor_type'] = 'windows'
        end
      end

      def executor_default(_config)
        []
      end
    end
  end
end
