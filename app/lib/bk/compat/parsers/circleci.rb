# frozen_string_literal: true

require_relative '../pipeline'
require_relative 'circleci/executors'
require_relative 'circleci/jobs'
require_relative 'circleci/orbs'
require_relative 'circleci/steps'
require_relative 'circleci/translator'
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
        load_elements!

        workflows = @config.fetch('workflows', {})
        workflows.delete('version')

        # Turn each work flow into a step group
        bk_groups = workflows.map { |wf, config| parse_workflow(wf, config) }

        # If no workflow is defined, it's expected that there's a `build` job
        bk_groups = [BK::Compat::GroupStep.new(steps: [@steps_by_key.fetch('build')])] if bk_groups.empty?
        # If there ended up being only 1 workflow, skip the group and just
        # pull the steps out.
        bk_groups = bk_groups.first.steps if bk_groups.length == 1

        Pipeline.new.tap { |p| p.steps.concat(bk_groups) }
      end

      private

      def load_elements!
        @config.fetch('orbs', {}).map { |key, config| load_orb(key, config) }
        @config.fetch('executors', {}).map { |key, config| load_executor(key, config) }
        @config.fetch('jobs', {}).map { |key, config| load_job(key, config) }
      end

      def string_or_key(job)
        case job
        when String
          [job, {}]
        when Hash
          raise 'Job is a hash with more than one key!?' unless job.length == 1

          job.dup.shift
        else
          raise "Job is not a hash or string! What could #{job.inspect} be!?"
        end
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::CircleCI)
