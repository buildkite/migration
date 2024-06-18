# frozen_string_literal: true

require_relative '../../pipeline/plugin'
require_relative '../../pipeline/step'

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def executor_docker(config)
        first, *rest = config # split first configuration

        BK::Compat::CircleCISteps::CircleCIStep.new.tap do |step|
          step.agents['executor_type'] = 'docker'
          step << executor_docker_auth_plugin(first.fetch('auth', {}))
          step << executor_docker_aws_auth(first.fetch('aws-auth', {}))

          step << (rest.empty? ? executor_docker_plugin(first) : executor_docker_compose_plugin(first, *rest))
        end
      end

      def executor_docker_auth_plugin(auth_config)
        return [] if auth_config.empty?

        BK::Compat::Plugin.new(
          name: 'docker-login',
          config: {
            'username' => auth_config['username'],
            'password-env' => auth_config['password'].delete_prefix('$')
          }
        )
      end

      def executor_docker_aws_auth(config)
        return [] if config.empty?

        url_regex = '^(?:[^/]+//)?(?<account-ids>\d+).dkr.ecr.(?<region>[^.]+).amazonaws.com'
        cfg = config['image'].match(url_regex).named_captures

        cfg[:login] = true
        cfg['assume-role'] = { 'role-arn' => config['oidc_role_arn'] } if config.include?('oidc_role_arn')

        BK::Compat::CircleCISteps::CircleCIStep.new(
          plugins: [BK::Compat::Plugin.new(name: 'ecr', config: cfg)]
        ).tap do |step|
          if config.include?('aws_access_key_id')
            step.add_commands('# Configure the agent to have the appropriate credentials for ECR auth')
          end
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

      def executor_docker_compose_plugin(*apps)
        containers = {}
        apps.each_with_index do |app, i|
          config = app.slice('image', 'entrypoint', 'user', 'command', 'environment')
          name = config.fetch('name', "service#{i}")

          containers[name] = config
        end

        conf = { 'services' => containers }
        cmds = [
          '# to make multiple images work, add the following composefile to your repository',
          "cat > compose.yaml << EOF\n#{conf.to_yaml}\nEOF"
        ]
        plugin_config = { 'run' => apps[0].fetch('name', 'service0') }

        BK::Compat::CircleCISteps::CircleCIStep.new(
          key: 'docker compose',
          commands: cmds,
          agents: { 'executor_type' => 'docker_compose' },
          plugins: [
            BK::Compat::Plugin.new(
              name: 'docker-compose',
              config: plugin_config
            )
          ]
        )
      end
    end
  end
end
