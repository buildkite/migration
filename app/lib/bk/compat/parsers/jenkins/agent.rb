# frozen_string_literal: true

require_relative '../../models/steps/command'
require_relative '../../models/plugin'

module BK
  module Compat
    # GitHub Actions converter
    class Jenkins
      private

      def translate_agent(agent)
        return CommandStep.new(agents: { 'label' => agent }) if agent.is_a?(String)
        return nil unless agent.is_a?(Hash)
        return nil if agent.include?('any') || agent.include?('none')

        %w[agent docker dockerfile kubernetes].each do |key|
          return send("translate_agent_#{key}", agent[key]) if agent.include?(key)
        end

        translate_agent_general(agent.fetch('node', agent))
      end

      def translate_agent_docker(docker)
        docker = { 'image' => docker } unless docker.is_a?(Hash)

        CommandStep.new(
          plugins: [
            Plugin.new(name: 'docker', config: docker.slice('image'))
          ]
        ).tap do |cmd|
          cmd.agents = { label: docker['label'] } if docker['label']

          if docker.include?('registryUrl') || docker.include?('registryCredentialsId')
            cmd << '# Configure Docker registry credentials with the corresponding plugin'
          end

          cmd << '# Docker args are passed as other options to the docker plugin' if docker.include?('args')
        end
      end

      def translate_agent_dockerfile(dockerfile)
        CommandStep.new(commands: docker_build_command(dockerfile)).tap do |cmd|
          cmd.agents = { label: dockerfile['label'] } if dockerfile['label']

          if dockerfile.include?('registryUrl') || dockerfile.include?('registryCredentialsId')
            cmd << '# Configure Docker registry credentials with the corresponding plugin'
          end

          cmd << '# Push this image to a registry and use it in other steps with the docker plugin'
        end
      end

      def translate_agent_general(config)
        CommandStep.new(
          agents: { label: config['label'] }
        ).tap do |cmd|
          cmd << '# Workspace is defined on the agent' if config.include?('customWorkspace')
          cmd << '# Agents are re-used by default (but steps are independent)' if config.include?('reuseNode')
        end
      end

      def translate_agent_kubernetes(_kube)
        CommandStep.new(
          plugins: [
            Plugin.new(name: 'kubernetes')
          ],
          commands: [
            '# Kubernetes config is mostly defined in the cluster deployment'
          ]
        )
      end

      def docker_build_command(config)
        build = %w[docker build]
        if config.is_a?(Hash) && !config.empty?
          build.append("-f #{config['filename']}") if config['filename']
          build << config.values_at('args', 'additionalBuildArgs', 'dir')
        else
          build << '.'
        end

        build.compact.join(' ')
      end
    end
  end
end
