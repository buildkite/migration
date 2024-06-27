# frozen_string_literal: true

require_relative '../translator'
require_relative '../pipeline'
require_relative '../pipeline/step'
require_relative 'harness/steps'
require_relative 'harness/stage'

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
        stages = @config['pipeline']['stages']

        bk_groups = stages.map { |stage| parse_stage(**stage['stage'].transform_keys(&:to_sym)) }

        Pipeline.new(
          steps: bk_groups.flatten.compact
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
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::Harness)
