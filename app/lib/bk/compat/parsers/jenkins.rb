# frozen_string_literal: true

require_relative '../models/steps/command'

require_relative 'jenkins/agent'

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
        default_agent = translate_agent(@config['pipeline']['agent'])
        Pipeline.new(
          steps: translate_stages(@config['pipeline']['stages'], default_agent)
        ).tap do |pipeline|
          pipeline.agents = default_agent.agents unless default_agent.nil?
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
            cmd << translate_agent(stage['agent']) if stage['agent']
            cmd << stage['steps']
          end
        end
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::GitHubActions)
