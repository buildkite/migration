# frozen_string_literal: true

require_relative '../translator'
require_relative '../pipeline'
require_relative 'circleci/executors'
require_relative 'circleci/jobs'
require_relative 'circleci/orbs'
require_relative 'circleci/steps'
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
        # sorting is important
        config = YAML.safe_load(text, aliases: true)
        mandatory_keys = %w[jobs version workflows].freeze

        if mandatory_keys & config.keys == mandatory_keys
          true
        else
          # legacy format support
          config.fetch('version', 2.1) == 2 && config['jobs'].include?('build')
        end
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text, aliases: true)
        @now = Time.now
        @options = options
        @commands_by_key = {}
        @executors = {}

        BK::Compat::CircleCISteps::Builtins.new(
          register: method(:register_translator),
          recursor: method(:translate_steps)
        )
      end

      def parse
        load_elements!

        workflows = @config.fetch('workflows', {})
        workflows.delete('version')

        # Turn each work flow into a step group
        bk_groups = workflows.map { |wf, config| parse_workflow(wf, config) }

        Pipeline.new.tap { |p| p.steps.concat(simplify_group(bk_groups)) }
      end

      private

      def load_elements!
        # order is important
        @config.fetch('orbs', {}).map { |key, config| load_orb(key, config) }
        @config.fetch('executors', {}).map { |key, config| load_executor(key, config) }
        @config.fetch('commands', {}).map { |key, config| load_command(key, config) }
        @config.fetch('jobs', {}).map { |key, config| load_job(key, config) }
      end

      def simplify_group(groups)
        # If no workflow is defined, it's expected that there's a `build` job
        groups = [BK::Compat::GroupStep.new(steps: [@commands_by_key['build'].instantiate({})])] if groups.empty?

        # If there ended up being only 1 workflow, skip the group and just
        # pull the steps out.
        groups = groups.first.steps.each { |step| step.conditional = groups.first.conditional } if groups.length == 1

        groups
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
