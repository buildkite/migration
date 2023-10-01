# frozen_string_literal: true

require_relative 'util'

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def parse_workflow(wf_name, wf_config)
        bk_steps = wf_config.fetch('jobs').map do |job|
          key, config = string_or_key(job)

          @steps_by_key.fetch(key).dup.tap do |step|
            step.depends_on = config.fetch('requires', [])

            # rename step (to respect dependencies and avoid clashes)
            step.key = config.fetch('name', key)
            step.conditional = parse_filters(config.fetch('filters', {}))
          end
        end

        BK::Compat::GroupStep.new(
          label: ":circleci: #{wf_name}",
          key: wf_name,
          steps: bk_steps
        )
      end

      def parse_filters(config)
        branches = build_condition(config.fetch('branches', {}), 'build.branch')
        tags = build_condition(config.fetch('tags', {}), 'build.tag')

        xxor(branches, tags)
      end

      def build_condition(filters, key)
        only = logic_builder(key, '=', string_or_list(filters.fetch('only', [])), ' || ')
        ignore = logic_builder(key, '!', string_or_list(filters.fetch('ignore', [])), ' && ')

        xxor(only, ignore)
      end

      def logic_builder(key, operator, elements, joiner)
        elements.map do |spec|
          negator = spec.start_with?('/') ? '~' : '='
          "#{key} #{operator}#{negator} #{spec}"
        end.join(joiner)
      end

      def xxor(first, second, separator = '&&')
        if first.to_s.empty? && second.to_s.empty?
          nil
        elsif !first.to_s.empty? && !second.to_s.empty?
          "(#{first}) #{separator} (#{second})"
        else
          # one of them is empty we don't care which
          "#{first}#{second}"
        end
      end
    end
  end
end
