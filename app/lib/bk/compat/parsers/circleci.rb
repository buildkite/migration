# frozen_string_literal: true

require_relative '../pipeline'
require_relative 'circleci/executors'
require_relative 'circleci/jobs'
require_relative 'circleci/orbs'
require_relative 'circleci/steps'
require_relative 'circleci/translator'
require_relative 'circleci/util'
require_relative 'circleci/workflows'

module BK
  module Compat
    # CircleCI translation scaffolding
    class CircleCI
      include StepTranslator
      require 'yaml'

      def self.name
        'Circle CI'
      end

      def self.option
        'circleci'
      end

      def self.matches?(text)
        keys = YAML.safe_load(text, aliases: true).keys
        mandatory_keys = %w[version jobs workflows].freeze
        keys & mandatory_keys == mandatory_keys
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text, aliases: true)
        @now = Time.now
        @options = options
        @steps_by_key = {}
        @executors = {}

        builtin_steps = BK::Compat::CircleCISteps::Builtins.new
        register_translator(*builtin_steps.register)
      end

      def parse
        bk_pipeline = Pipeline.new

        @config.fetch('orbs', {}).map { |key, config| load_orb(key, config) }
        @config.fetch('executors', {}).map { |key, config| load_executor(key, config) }
        @config.fetch('jobs', {}).map { |key, config| load_job(key, config) }

        workflows = @config.fetch('workflows', {})
        workflows.delete('version')
        # Turn each work flow into a step group
        bk_groups = workflows.map { |wf, config| parse_workflow(wf, config) }

        if bk_groups.empty?
          # If no workflow is defined, it's expected that there's a `build` job
          bk_groups = [@steps_by_key.fetch('build')]
        elsif bk_groups.length == 1
          # If there ended up being only 1 workflow, skip the group and just
          # pull the steps out.
          bk_groups = bk_groups.first.steps
        end

        bk_pipeline.steps.concat(bk_groups)

        bk_pipeline
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::CircleCI)
