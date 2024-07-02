# frozen_string_literal: true

require_relative '../translator'
require_relative '../pipeline'
require_relative '../pipeline/step'
require_relative 'bitrise/steps'
require_relative 'bitrise/workflows'

module BK
  module Compat
    # Bitrise translation scaffolding
    class Bitrise
      require 'yaml'

      def self.name
        'Bitrise'
      end

      def self.option
        'bitrise'
      end

      def self.matches?(text)
        config = YAML.safe_load(text, aliases: true)

        # Only required field for Bitrise YAML is format_version
        mandatory_keys = %w[format_version].freeze

        config.is_a?(Hash) && mandatory_keys & config.keys == mandatory_keys
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text, aliases: true)
        @options = options

        register_translators!
      end

      def parse
        workflows = @config.fetch('workflows', {})
        bk_groups = workflows.map { |wf_name, wf_config| parse_workflow(wf_name, wf_config) }

        Pipeline.new(
          steps: bk_groups
        )
      end

      private

      def register_translators!
        @translator = BK::Compat::StepTranslator.new
        @translator.register(BK::Compat::BitriseSteps::Translator.new)
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::Bitrise)
