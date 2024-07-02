# frozen_string_literal: true

module BK
  module Compat
    # Bitrise translation of workflows
    class Bitrise
      STEP_TYPE_REGEX = /([a-zA-Z]*)@(\d*|0)(\.((\d*)|0)){0,3}/

      private

      def parse_workflow(wf_name, wf_config)
        bk_steps = parse_workflow_steps(wf_config)

        BK::Compat::GroupStep.new(
          label: wf_name,
          key: wf_name,
          steps: bk_steps
        )
      end

      def parse_workflow_steps(wf_config)
        wf_config['steps'].map { |step| process_step(step) }
      end

      def process_step(step)
        # Obtain steps' key, config, and normalize it
        step_key, step_config = step.first
        step_key_normalized = normalize_step_type(step_key)

        @translator.translate_step(step_key_normalized, step_config)
      end

      def normalize_step_type(step)
        # Pull out the step type without its version to match translator's supported steps
        step.match?(STEP_TYPE_REGEX) ? step.match(STEP_TYPE_REGEX)[1] : step
      end
    end
  end
end
