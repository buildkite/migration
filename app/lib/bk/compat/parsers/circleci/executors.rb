# frozen_string_literal: true

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def parse_executor(name, config)
        existing = config.slice('docker', 'machine', 'macos', 'windows')
        
        # only one of these must exist
        raise "Invalid executor configuration #{config}" if existing.length != 1

        # parse the existing one
        key = existing.keys.first
        @executors[name] = BK::Compat::CommandStep.new(key: key).tap do |step|
          step.env = config.fetch('environment', {})
          step.commands << "cd #{config['working_directory']}" if config.include?('working_directory')
          step.commands << '# shell is environment-dependent and should be configured in the agent' if config.include?('shell')
          step.agents['resource_class'] = config['resource_class'] if config.include?('resource_class')
          step << send("executor_#{key}", existing[key])
        end
      end

      def executor_docker(_config)
        BK::Compat::CommandStep.new().tap do |step|
          step.agents['executor_type'] = 'docker'
        end
      end

      def executor_machine(config)
        BK::Compat::CommandStep.new().tap do |step|
          step.agents['executor_type'] = 'machine'
          step.agents['executor_image'] = config['image']
          step.commands = ['# Docker Layer Caching must be configured in the infra of the agent'] if config.include?('docker_layer_caching')
        end
      end

      def executor_macos(config)
        BK::Compat::CommandStep.new().tap do |step|
          step.agents['executor_type'] = 'osx'
          step.agents['executor_xcode'] = config['xcode']
        end
      end

      def executor_windows(_config)
        step.agents['executor_type'] = 'windows'
      end
    end
  end
end
