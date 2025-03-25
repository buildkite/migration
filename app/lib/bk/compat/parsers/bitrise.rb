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
        return {} unless vars

        BK::Compat::Bitrise::EnvHelper.process_env_variables(vars)
      end

      private

      def register_translators!
        @translator = BK::Compat::StepTranslator.new
        @translator.register(BK::Compat::BitriseSteps::Translator.new)
      end

      def parse_workflow(wf_name, wf_config)
        stack_value = wf_config.dig('meta', 'bitrise.io', 'stack')
        agents = stack_value ? { stack: stack_value } : {}
        cmd_step = BK::Compat::CommandStep.new(label: wf_name, key: wf_name, agents: agents)
        wf_config['steps'].each do |step|
          step_key, step_config = step.first
          cmd_step << translate_step(step_key, step_config)
        end
        process_workflow_envs(wf_config, cmd_step)
        cmd_step
      end

      def process_workflow_envs(wf_config, cmd_step)
        cmd_step.env.merge!(BK::Compat::Bitrise::EnvHelper.process_env_variables(wf_config['envs']))
      end

      def translate_step(step_key, step_config)
        step_inputs = (step_config['inputs'] || {}).reduce({}, :merge)
        load_workflow_step(step_key, step_inputs).tap do |translated_step|
          if translated_step.respond_to?(:agents) && step_config.include?('stack')
            translated_step.agents ||= {}
            translated_step.agents[:stack] = step_config['stack']
          end

          # Apply environment variables if available
          apply_env_config(translated_step, step_config)
        end
      end

      def apply_env_config(step, config)
        return unless step.respond_to?(:env) && config['envs']

        step.env.merge!(BK::Compat::Bitrise::EnvHelper.process_env_variables(config['envs']))
      end

      def load_workflow_step(step_key, step_inputs)
        step_key_normalized = step_key.split('@').first
        # Translate step with normalized key (for translator) and its input configuration
        @translator.translate_step(step_key_normalized, step_inputs)
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::Bitrise)
