# frozen_string_literal: true

require_relative '../translator'
require_relative '../models/pipeline'
require_relative 'bitrise/steps'
require_relative 'bitrise/workflows'
require_relative 'bitrise/env_helper'

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
        bk_steps = workflows.map { |wf_name, wf_config| parse_workflow(wf_name, wf_config) }

        stack_value = @config.dig('meta', 'bitrise.io', 'stack')
        agents = stack_value ? { stack: stack_value } : {}

        Pipeline.new(
          steps: bk_steps,
          agents: agents,
          env: process_app_envs(@config.dig('app', 'envs') || {})
        )
      end

      def process_app_envs(vars)
        return {} unless vars # takes care of empty vars and nils

        result = {}
        BK::Compat::Bitrise::EnvHelper.process_env_variables(vars, result)
        result
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
