# frozen_string_literal: true

module BK
  module Compat
    # GitHub Actions converter
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

        mandatory_keys = ['agent', 'stages']
        
        # Mandatory keys are part of the pipeline element
        config.is_a?(Hash) && mandatory_keys & config.fetch('pipeline', {}).keys == mandatory_keys
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text)
        @options = options

        register_translators!
      end

      def parse
        Pipeline.new(
          steps: 'Can not translate this just yet',
        )
      end

      private

      def register_translators!
        @translator = BK::Compat::StepTranslator.new

        @translator.register()
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::GitHubActions)
