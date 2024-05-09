# frozen_string_literal: true

require_relative '../error'
require_relative '../translator'
require_relative '../models/pipeline'
require_relative 'gha/branches'
require_relative 'gha/jobs'
require_relative 'gha/steps'
require_relative 'gha/steps/actions'

module BK
  module Compat
    # GitHub Actions converter
    class GitHubActions
      include StepTranslator
      require 'yaml'

      def self.name
        'GitHub Actions'
      end

      def self.option
        'gha'
      end

      def self.matches?(text)
        config = YAML.safe_load(text)
        # YAML translates the `on` key in YAML to ruby's `true` boolean
        mandatory_keys = ['jobs', true]

        config.is_a?(Hash) && mandatory_keys & config.keys == mandatory_keys
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text)
        @options = options

        register_translators!
      end

      def parse
        # Pipeline with steps defined as jobs
        defaults = @config.fetch('defaults', {})

        # push data for branch filtering
        # `on` key in YAML is translated to ruby's `true` boolean
        branches = translate_branch_filters(@config.fetch(true, {}))

        steps = @config.fetch('jobs', []).map do |key, config|
          parse_job(key, defaults.merge(config)).tap do |bk_step|
            bk_step.branches = branches
          end
        end

        Pipeline.new(
          steps: steps,
          env: @config.fetch('env', {})
        )
      end

      private
      
      def register_translators!
        GHABuiltins.new(register: method(:register_translator))
        GHAActions.new(register: method(:register_translator))
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::GitHubActions)
