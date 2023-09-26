# frozen_string_literal: true

require_relative 'jobs'
require_relative 'logic'

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def parse_workflow(wf_name, wf_config)
        bk_steps = wf_config.fetch('jobs').map { |job| process_workflow_job(job) }
        condition = process_workflow_conditions(wf_config.slice('when', 'unless'))

        BK::Compat::GroupStep.new(
          label: ":circleci: #{wf_name}",
          key: wf_name,
          steps: bk_steps,
          conditional: condition
        )
      end

      def process_workflow_job(job)
        key, config = string_or_key(job)

        if config['type'] == 'approval'
          BK::Compat::BlockStep(key, depends_on: config.fetch('requires', []))
        else
          process_job(key, config)
        end
      end

      def process_workflow_conditions(config)
        return nil if config.empty?

        raise 'Can not have both when and unless in a workflow' if config.length > 1

        key = config.keys.first

        tree = key == 'unless' ? { 'not' => config[key] } : config[key]
        parse_condition(tree)
      end

      def process_job(key, config)
        @commands_by_key[key].instantiate(config.fetch('parameters', {})).tap do |step|
          step >> translate_steps(config['pre-steps'])
          step << translate_steps(config['post-steps'])
          step.depends_on = config.fetch('requires', [])

          # rename step (to respect dependencies and avoid clashes)
          step.key = config.fetch('name', key)
          step.conditional = parse_filters(config.fetch('filters', {}))
        end
      end

      def parse_filters(config)
        branches = build_condition(config.fetch('branches', {}), 'build.branch')
        tags = build_condition(config.fetch('tags', {}), 'build.tag')

        BK::Compat.xxand(branches, tags)
      end
    end
  end
end
