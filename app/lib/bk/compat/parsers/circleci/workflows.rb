# frozen_string_literal: true

require_relative 'jobs'
require_relative 'logic'
require_relative '../../error'

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
          BK::Compat::BlockStep.new(key: key, depends_on: config.fetch('requires', []))
        elsif @commands_by_key.include?(key)
          process_job(key, config)
        else
          raise BK::Compat::Error::ConfigurationError,
                "Job '#{key}' is not defined"
        end
      end

      def process_workflow_conditions(config)
        return nil if config.empty?

        raise 'Can not have both when and unless in a workflow' if config.length > 1

        key = config.keys.first

        tree = key == 'unless' ? { 'not' => config[key] } : config[key]
        BK::Compat::CircleCI.parse_condition(tree)
      end

      def process_job(key, config)
        get_command(key, config).tap do |step|
          step >> translate_steps(config['pre-steps'])
          step << translate_steps(config['post-steps'])
        end.instantiate(config)
      end

      def get_command(key, config)
        @commands_by_key[key].dup.tap do |step|
          # rename step (to respect dependencies and avoid clashes)
          step.key = config.fetch('name', key)
          step.depends_on = config.fetch('requires', [])
          step.conditional = parse_filters(config.fetch('filters', {}))
          step.matrix = parse_matrix(config.fetch('matrix', {}))
        end
      end

      def parse_filters(config)
        branches = BK::Compat::CircleCI.build_condition(config.fetch('branches', {}), 'build.branch')
        tags = BK::Compat::CircleCI.build_condition(config.fetch('tags', {}), 'build.tag')

        BK::Compat.xxand(branches, tags)
      end

      def parse_matrix(config)
        params, exclude = config.values_at('parameters', 'exclude')

        return {} if params.nil?

        {
          setup: params,
          adjustments: exclude&.map { |x| { with: x, skip: true } }
        }.compact
      end
    end
  end
end
