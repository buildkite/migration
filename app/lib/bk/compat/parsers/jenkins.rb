# frozen_string_literal: true

require_relative '../models/steps/command'

require_relative 'jenkins/agent'
require_relative 'jenkins/parameters'

module BK
  module Compat
    # Jenkins YAML converter
    class Jenkins
      require 'yaml'

      def self.name
        'Jenkins YAML Declarative Pipeline'
      end

      def self.option
        'jenkins'
      end

      def self.matches?(text)
        config = YAML.safe_load(text)

        mandatory_keys = %w[agent stages].freeze

        # Mandatory keys are part of the pipeline element
        config.is_a?(Hash) && mandatory_keys & config.fetch('pipeline', {}).keys == mandatory_keys
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text)
        @options = options

        register_translators!
      end

      def parse
        config = @config['pipeline']
        default_agent = translate_agent(config['agent'])
        Pipeline.new(
          steps: translate_stages(config['stages'], default_agent),
          env: config.fetch('environment', {})
        ).tap do |pipeline|
          pipeline.agents = default_agent.agents unless default_agent.nil?
          pipeline.steps.prepend(translate_general_keys(config))
        end
      end

      private

      def register_translators!
        @translator = BK::Compat::StepTranslator.new

        @translator.register
      end

      def translate_stages(stages, default_agent)
        default_agent = CommandStep.new if default_agent.nil?
        stages.map do |stage|
          default_agent.instantiate.tap do |cmd|
            cmd.key = stage['stage']
            cmd.env = stage.fetch('environment', {})
            cmd << translate_agent(stage['agent']) if stage['agent']
            cmd << stage['steps']
          end
        end
      end

      def translate_general_keys(config)
        [
          translate_libraries(config['library']),
          translate_parameters(config['parameters'])
        ].flatten.compact
      end

      def translate_libraries(library)
        return nil if library.nil?

        CommandStep.new(
          label: 'Libraries',
          commands: '# Libraries are not supported at this time :('
        )
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::GitHubActions)
