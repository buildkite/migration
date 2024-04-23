# frozen_string_literal: true

require_relative '../translator'
require_relative '../pipeline'
require_relative '../pipeline/step'
require_relative 'bitbucket/steps'

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

        BK::Compat::BitBucketSteps::Step.new(register: method(:register_translator))
      end

      def parse
        # custom is also valid, but not supported just yet
        pps = %w[branches default pull-requests tags].freeze
        image_base = @config['image']
        conf = @config['pipelines']
        Pipeline.new(
          steps: pps.map { |p| 
            parse_pipeline(conf[p], image_base) if conf.include?(p)
          }.compact
        )
      end

      private

      def simplify_group(group)
        # If there ended up being only 1 stage, skip the group and just
        # pull the steps out.
        if group.steps.length == 1
          group.steps[0].conditional = group.conditional
          group = group.steps.first
        end
        group
      end

      def parse_pipeline(conf, image_base)
        if conf.is_a?(Array)
          simplify_group(BK::Compat::GroupStep.new(
            key: 'group1',
            steps: conf.map do |s|
              s['step']['image'] = image_base if s['step']['image'].nil? && !image_base.nil?
              translate_step(s)
            end
          ))
        else
          BK::Compat::CommandStep.new(
            label: 'import step',
            commands: [ "Import steps not supported yet #{conf}" ]
          )
        end
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::BitBucket)
