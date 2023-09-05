# frozen_string_literal: true

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def parse_workflow(wf_name, wf_config)
        bk_steps = wf_config.fetch('jobs').map do |job|
          case job
          when String
            key = job
            config = {}
          when Hash
            key = job.keys.first
            config = job[key]
          else
            raise "Job is not a hash or string! What could #{job.inspect} be!?"
          end

          step = @steps_by_key.fetch(key).dup
          step.depends_on = config.fetch('requires', [])

          # rename step (to respect dependencies and avoid clashes)
          step.key = config.fetch('name', key)

          step
        end

        BK::Compat::GroupStep.new(
          label: ":circleci: #{wf_name}",
          key: wf_name,
          steps: bk_steps
        )
      end
    end
  end
end
