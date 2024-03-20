# frozen_string_literal: true

require_relative '../translator'
require_relative '../pipeline'
require_relative '../pipeline/step'
require_relative './harness/steps/run'
require_relative './harness/steps/background'

module BK
  module Compat
    # Harness translation scaffolding
    class Harness
      include StepTranslator
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

        if config.is_a?(String)
          false
        elsif mandatory_keys & config.keys == mandatory_keys
          config['pipeline'].include?('stages')
        else
          false
        end
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text, aliases: true)
        @options = options

        BK::Compat::HarnessSteps::Run.new(register: method(:register_translator))
      end

      def parse
        # map stages to groups
        grp = BK::Compat::GroupStep.new(
          label: @config['pipeline']['name'],
          key: @config['pipeline']['identifier']
        )
        
        grp.steps = @config['pipeline']['stages'].map { |stage|
          parse_stage(**stage['stage'].transform_keys(&:to_sym))
        }

        Pipeline.new(steps: [simplify_group(grp)])
      end

      private

      def simplify_group(group)
        # If there ended up being only 1 stage, skip the group and just
        # pull the steps out.
        if group.steps.length == 1 then
          group.steps.map! { |step| step.conditional = group.conditional } 
          group = groups.steps.first
        end
        group
      end

      def parse_stage(name:, identifier:, spec:, **rest)
        BK::Compat::CommandStep.new(
          label: name,
          key: identifier
        ).tap { |cmd|
          spec.dig('execution', 'steps').map { |step|
            cmd << translate_step(**step['step'].transform_keys(&:to_sym))
          }
        }
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::Harness)
