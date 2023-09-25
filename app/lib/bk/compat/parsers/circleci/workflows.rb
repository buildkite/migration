# frozen_string_literal: true

require_relative 'jobs'

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def parse_workflow(wf_name, wf_config)
        bk_steps = wf_config.fetch('jobs').map do |job|
          key, config = string_or_key(job)

          if config['type'] == 'approval'
            BK::Compat::BlockStep(key, depends_on: config.fetch('requires', []))
          else
            process_job(key, config)
          end
        end

        BK::Compat::GroupStep.new(
          label: ":circleci: #{wf_name}",
          key: wf_name,
          steps: bk_steps
        )
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

      def build_condition(filters, key)
        only = logic_builder(key, '=', string_or_list(filters.fetch('only', [])), ' || ')
        ignore = logic_builder(key, '!', string_or_list(filters.fetch('ignore', [])), ' && ')

        BK::Compat.xxand(only, ignore)
      end

      def logic_builder(key, operator, elements, joiner)
        elements.map do |spec|
          negator = spec.start_with?('/') ? '~' : '='
          "#{key} #{operator}#{negator} #{spec}"
        end.join(joiner)
      end

      def string_or_list(object)
        object.is_a?(String) ? [object] : object
      end
    end
  end
end
