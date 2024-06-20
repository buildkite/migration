# frozen_string_literal: true

require_relative '../translator'
require_relative '../models/pipeline'
require_relative '../models/steps/group'
require_relative 'harness/steps'

module BK
  module Compat
    # Harness translation scaffolding
    class Harness
      require 'yaml'

      def self.name
        'Harness'
      end

      def self.option
        'harness'
      end

      def self.matches?(text)
        # sorting is important
        config = YAML.safe_load(text, aliases: true)
        mandatory_keys = %w[pipeline].freeze

        if config.is_a?(Hash) && mandatory_keys & config.keys == mandatory_keys
          config['pipeline'].include?('stages')
        else
          false
        end
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text, aliases: true)
        @options = options

        register_translators!
      end

      def parse
        Pipeline.new(
          steps: @config['pipeline']['stages'].map do |stage|
            parse_stage(**stage['stage'].transform_keys(&:to_sym))
          end
        )
      end

      private

      def default_step(*, **)
        BK::Compat::CommandStep.new(
          commands: @translator.default_value(*, **)
        )
      end

      def register_translators!
        @translator = BK::Compat::StepTranslator.new(default: method(:default_step))
        @translator.register(BK::Compat::HarnessSteps::Translator.new)
      end

      def simplify_group(group)
        # If there ended up being only 1 stage, skip the group and just
        # pull the steps out.
        if group.steps.length == 1
          step = group.steps.first
          step.conditional = group.conditional
          group = step
        end
        group
      end

      def parse_stage(name:, identifier:, spec:, **_rest)
        grp = BK::Compat::GroupStep.new(
          label: name,
          key: identifier,
          steps: spec.dig('execution', 'steps').map do |step|
            @translator.translate_step(**step['step'].transform_keys(&:to_sym))
          end
        )

        simplify_group(grp)
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::Harness)
