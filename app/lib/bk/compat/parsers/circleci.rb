# frozen_string_literal: true

require_relative '../translator'
require_relative '../models/steps/group'

require_relative 'circleci/executors'
require_relative 'circleci/jobs'
require_relative 'circleci/orbs'
require_relative 'circleci/steps'
require_relative 'circleci/workflows'

module BK
  module Compat
    # CircleCI translation scaffolding
    class CircleCI
      require 'yaml'

      def self.name
        'Circle CI'
      end

      def self.option
        'circleci'
      end

      def load_orb(key, _config)
        case key
        when 'docker'
          @translator.register(CircleCISteps::DockerOrb.new)
        else
          @translator.register(CircleCISteps::GenericOrb.new(key))
        end
      end

      def self.matches?(text)
        # sorting is important
        config = YAML.safe_load(text, aliases: true)
        mandatory_keys = %w[jobs version workflows].freeze

        if config.is_a?(String)
          false
        elsif mandatory_keys & config.keys == mandatory_keys
          true
        else
          # legacy format support
          config.fetch('version', 2.1) == 2 && config['jobs'].include?('build')
        end
      rescue Psych::SyntaxError
        return false
      end

      def initialize(text, options = {})
        BK::Compat::Error::CompatError.safe_yaml do
          @config = YAML.safe_load(text, aliases: true)
          @now = Time.now
          @options = options
          @commands_by_key = {}
          @executors = {}

          register_translators!
        end
      end

      def parse
        load_elements!

        workflows = @config.fetch('workflows', {})
        workflows.delete('version')

        # Turn each work flow into a step group
        bk_groups = workflows.map { |wf, config| parse_workflow(wf, config) }

        # If no workflow is defined, it's expected that there's a `build` job
        bk_groups = [BK::Compat::GroupStep.new(steps: [@commands_by_key['build'].instantiate({})])] if bk_groups.empty?

        Pipeline.new(steps: bk_groups)
      end

      private

      def register_translators!
        @translator = BK::Compat::StepTranslator.new(recursor: method(:translate_steps).to_proc)
        @translator.register(
          BK::Compat::CircleCISteps::Builtins.new
        )
      end

      def load_elements!
        # order is important
        @config.fetch('orbs', {}).map { |key, config| load_orb(key, config) }
        @config.fetch('executors', {}).map { |key, config| load_executor(key, config) }
        @config.fetch('commands', {}).map { |key, config| load_command(key, config) }
        @config.fetch('jobs', {}).map { |key, config| load_job(key, config) }
      end

      def translate_steps(step_list)
        return [] if step_list.nil?

        step_list.map do |circle_step|
          key, config = string_or_key(circle_step)
          @commands_by_key[key]&.instantiate(config) || @translator.translate_step(key, config)
        end
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
