# frozen_string_literal: true

require_relative '../models/steps/command'

require_relative 'jenkins/agent'
require_relative 'jenkins/options'
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

        agent, default_step, prepend_steps = parse_general_keys(config)

        Pipeline.new(
          steps: config['stages'].map { |stg| translate_stage(stg, default_step) },
          env: config.fetch('environment', {})
        ).tap do |pipeline|
          pipeline.agents = agent
          pipeline.steps.prepend(*prepend_steps)
        end
      end

      private

      def register_translators!
        @translator = BK::Compat::StepTranslator.new

        @translator.register
      end

      def translate_stage(stage, default_step)
        default_step = CommandStep.new if default_step.nil?
        default_step.instantiate.tap do |cmd|
          cmd.key = stage['stage']
          cmd.env = stage.fetch('environment', {})
          cmd << translate_agent(stage['agent'])
          cmd << translate_options(stage['options'])
          cmd << stage['steps']
        end
      end

      def parse_general_keys(config)
        default_step = CommandStep.new.tap do |step|
          step << translate_agent(config['agent'])
          step << translate_options(config['options'])
        end

        agents = default_step.agents
        default_step.agents = {}

        [agents, default_step, translate_general_keys(config)]
      end

      def translate_general_keys(config)
        [
          translate_libraries(config['library']),
          translate_triggers(config['triggers']),
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

      def translate_triggers(triggers)
        return nil if triggers.nil?

        CommandStep.new(
          label: 'Triggers',
          commands: '# Triggers are configured for the pipeline in the UI'
        )
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::GitHubActions)
