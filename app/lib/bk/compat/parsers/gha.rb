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

        # Load elements
        load_elements
        puts("Jobs: #{@jobs}")

        # Loop through all jobs defined
        @jobs.each do |job|

          # Extract the Job's name
          job_name = job[0]
          job_list = []
          job_needs = @jobs[job_name]['needs']

          # Put info to console
          puts("Job name: #{job_name}")
          puts("Steps: #{@jobs[job_name]['steps']}")
          puts("Job needs: #{job_needs}")
          
          # For each job, extract the name/run
          @jobs[job_name]['steps'].each do |step|
            bk_step = BK::Compat::CommandStep.new(
              label: step['name'],
              commands: step['run']
            )
            job_list.append(bk_step)

          end 

          # Create a Group Step
          steps = BK::Compat::GroupStep.new(
            label: ":github:: #{job_name}",
            key: job_name,
            steps: job_list,
            depends_on: job_needs
          )

          ## Insert Group into pipeline
          bk_pipeline.steps << steps
        end

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
