# frozen_string_literal: true

require_relative '../translator'
require_relative '../models/pipeline'
require_relative '../pipeline/step'

require_relative 'bitbucket/import'
require_relative 'bitbucket/parallel'
require_relative 'bitbucket/stages'
require_relative 'bitbucket/steps'
require_relative 'bitbucket/variables'

module BK
  module Compat
    # BitBucket translation scaffolding
    class BitBucket
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

        register_translators!
      end

      def parse
        defaults = @config.slice('image', 'clone').merge(@config.fetch('options', {}))
        conf = @config['pipelines']

        main_steps = [parse_pipeline('default', conf['default'], defaults)]
        others = non_default_pipelines(defaults)
        Pipeline.new(
          steps: [main_steps, others].flatten.compact
        )
      end

      private

      def register_translators!
        @translator = BK::Compat::StepTranslator.new
        @translator.register(
          BK::Compat::BitBucketSteps::Import.new,
          BK::Compat::BitBucketSteps::Parallel.new,
          BK::Compat::BitBucketSteps::Stages.new,
          BK::Compat::BitBucketSteps::Step.new(definitions: @config.fetch('definitions', {})),
          BK::Compat::BitBucketSteps::Variables.new
        )
      end

      def non_default_pipelines(defaults)
        pps = %w[branches custom pull-requests tags].freeze
        others = pps.map do |p|
          named_pipelines(@config['pipelines'].fetch(p, {}), defaults, post: method("post_process_#{p.gsub('-', '_')}"))
        end
        definitions = named_pipelines(@config.dig('definitions', 'pipelines'), defaults)

        [others, definitions]
      end

      def named_pipelines(conf, defaults, post: method(:post_process_nothing))
        return [] if Hash(conf).empty?

        conf.map do |name, steps|
          post&.call(name, parse_pipeline(name, steps, defaults))
        end
      end

      def simplify_group(group)
        # if ther last step is a wait, remove it
        group.steps.pop if group.steps.last.is_a?(WaitStep)

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
        steps = Array(conf).map { |s| @translator.translate_step(s, defaults: defaults) }
        simplify_group(
          BK::Compat::GroupStep.new(
            label: name,
            steps: steps.flatten
          )
        )
      end

      def post_process_nothing(_name, steps)
        steps
      end

      def post_process_branches(name, steps)
        [steps].flatten.map do |s|
          s.conditional = "build.branch =~ /#{name.gsub('/', '\/')}/"
          s
        end
      end

      def post_process_custom(_name, steps)
        # custom pipelines are always manual
        BK::Compat::BitBucket.translate_trigger('manual', steps)
      end

      def post_process_pull_requests(name, steps)
        [steps].flatten.map do |s|
          s.conditional = "pull_request.id != null && build.branch =~ /#{name.gsub('/', '\/')}/"
          s
        end
      end

      def post_process_tags(name, steps)
        [steps].flatten.map do |s|
          s.conditional = "build.tag =~ /#{name.gsub('/', '\/')}/"
          s
        end
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::BitBucket)
