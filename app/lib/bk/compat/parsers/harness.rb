# frozen_string_literal: true

require_relative '../translator'
require_relative '../models/pipeline'
require_relative '../models/steps/command'

require_relative 'harness/stage'
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
      rescue Psych::SyntaxError
        return false
      end

      def initialize(text, options = {})
        BK::Compat::Error::CompatError.safe_yaml do
          @config = YAML.safe_load(text, aliases: true)
          @options = options

          register_translators!
        end
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
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::Harness)
