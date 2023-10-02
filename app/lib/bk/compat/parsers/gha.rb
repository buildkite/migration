# frozen_string_literal: true

require_relative '../error'
require_relative '../pipeline'
require_relative 'gha/jobs'

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
        # Load elements
        load_elements
        puts("Jobs: #{@jobs}")

        # Loop through all jobs defined
        parse_jobs(bk_pipeline = Pipeline.new)

        # Render the pipeline 
        bk_pipeline
      end

      def load_elements
        @jobs = @config.fetch('jobs')
      end

    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::GitHubActions)
