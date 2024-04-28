# frozen_string_literal: true

require_relative '../translator'
require_relative '../pipeline'
require_relative '../pipeline/step'

require_relative 'bitbucket/import'
require_relative 'bitbucket/stages'
require_relative 'bitbucket/steps'
require_relative 'bitbucket/variables'

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

        BK::Compat::BitBucketSteps::Import.new(register: method(:register_translator))
        BK::Compat::BitBucketSteps::Step.new(
          register: method(:register_translator),
          definitions: @config.fetch('definitions', {})
        )
        BK::Compat::BitBucketSteps::Variables.new(register: method(:register_translator))
      end

      def parse
        pps = %w[branches custom pull-requests tags].freeze
        defaults = @config.slice('image', 'clone').merge(@config.fetch('options', {}))
        conf = @config['pipelines']

        # TODO: change group1 to default
        main_steps = [parse_pipeline('group1', conf['default'], defaults)]
        others = pps.map do |p|
          named_pipelines(conf.fetch(p, {}), defaults)
          # post: method("post_process_#{p}".to_sym)
        end
        definitions = named_pipelines(@config.dig('definitions', 'pipelines'), defaults)
        Pipeline.new(
          steps: [main_steps, definitions, others].flatten.compact
        )
      end

      private

      def named_pipelines(conf, defaults)
        return [] if Hash(conf).empty?

        conf.map do |name, steps|
          parse_pipeline(name, steps, defaults)
        end
      end

      def simplify_group(group)
        # If there ended up being only 1 stage, skip the group and just
        # pull the steps out.
        if group.steps.length == 1
          group.steps[0].conditional = group.conditional
          return group.steps[0]
        elsif group.steps.empty?
          return []
        end

        group
      end

      def parse_pipeline(name, conf, defaults)
        steps = Array(conf).map { |s| translate_step(s, defaults: defaults) }
        simplify_group(
          BK::Compat::GroupStep.new(
            key: name,
            steps: steps.flatten
          )
        )
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::BitBucket)
