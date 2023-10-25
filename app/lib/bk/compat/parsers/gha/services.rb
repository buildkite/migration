# frozen_string_literal: true

module BK
  module Compat
    # Translate services to docker commands
    class GitHubActions
      def set_services(bk_step, services)
        return nil if services.nil?

        cmds = ['# It may be a good idea to use docker compose to start up job-specific services']
        cmds.concat(docker_cmds(services).flatten)
        bk_step.prepend_commands(cmds.compact)

        bk_step.add_commands("docker stop #{services.keys.join(' ')}")
      end

      def docker_cmds(services)
        services.map do |name, config|
          # All options map directly to a docker `create` command
          envs = config.fetch('env', {}).map { |k, v| "--env \"#{k}='#{v}'\"" }.join(' ')
          ports = config.fetch('ports', []).map { |p| "--expose '#{p}'" }.join(' ')
          vols = config.fetch('volumes', []).map { |v| "--volume '#{v}'" }.join(' ')

          [
            "echo 'Starting #{name} service'",
            config.include?('credentials') ? '# Warning: you should use the docker-login plugin to authenticate' : nil,
            "docker start --rm -d --name #{name} #{envs} #{ports} #{vols} #{config['options']} #{config['image']}"
          ]
        end
      end
    end
  end
end
