# frozen_string_literal: true

require_relative '../error'
require_relative '../pipeline'

module BK
  module Compat
    # GitHub Actions converter
    class GitHubActions
      require 'yaml'

      def self.name
        'GitHub Actions'
      end

      def self.option
        'gha'
      end

      def self.matches?(text)
        keys = YAML.safe_load(text).keys
        keys.include?('language') || keys.include?('rvm')
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text)
        @options = options
      end

      def parse
        bk_pipeline = Pipeline.new

        # Parse out name, run name
        jobs = @config.fetch('jobs')['explore']['steps'].each do |step|
          
          bk_step = BK::Compat::CommandStep.new(
            label: step['name'],
            commands: step['run']
          )

          # Insert to pipeline
          bk_pipeline.steps << bk_step        
        end

        # Render the pipeline 
        bk_pipeline
      end

    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::GitHubActions)
