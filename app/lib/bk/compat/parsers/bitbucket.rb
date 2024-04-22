# frozen_string_literal: true

require_relative '../translator'
require_relative '../pipeline'
require_relative '../pipeline/step'

module BK
  module Compat
    # BitBucket translation scaffolding
    class BitBucket
      include StepTranslator
      require 'yaml'

      def self.name
        'BitBucket'
      end

      def self.option
        'bitbucket'
      end

      def self.matches?(text)
        config = YAML.safe_load(text, aliases: true)

        # only required field is pipelines
        mandatory_keys = %w[pipelines].freeze

        config.is_a?(Hash) && mandatory_keys & config.keys == mandatory_keys
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text, aliases: true)
        @options = options
      end

      def parse
        pps = %w[branches custom default pull-requests tags].freeze
        conf = @config['pipelines']
        Pipeline.new(
          steps: pps.map { |p| 
            parse_pipeline(**conf[p]) if conf.include?(p)
          }.compact
        )
      end

      private

      def simplify_group(group)
        # If there ended up being only 1 stage, skip the group and just
        # pull the steps out.
        if group.steps.length == 1
          group.steps.map! { |step| step.conditional = group.conditional }
          group = groups.steps.first
        end
        group
      end

      def parse_pipeline(name:, identifier:, spec:, **_rest)
        BK::Compat::CommandStep.new(
          label: name,
          key: identifier
        ).tap do |cmd|
          spec.dig('execution', 'steps').map do |step|
            cmd << translate_step(**step['step'].transform_keys(&:to_sym))
          end
        end
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::BitBucket)
