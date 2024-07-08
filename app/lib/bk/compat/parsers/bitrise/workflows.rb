# frozen_string_literal: true

module BK
  module Compat
    # Bitrise translation of workflows
    class Bitrise
      private

      def parse_workflow(wf_name, wf_config)
        bk_steps = process_workflow_steps(wf_name)

        BK::Compat::GroupStep.new(
          label: wf_name,
          key: wf_name,
          steps: [bk_steps]
        )
      end

      def process_workflow_steps(wf_name)
        # Extend for other types of steps - approvals/waits for example.
        BK::Compat::CommandStep.new(label: wf_name, key: wf_name).tap do |cmd_step|
          wf_config['steps'].each do |step|
            step_key, step_config = step.first
            step_inputs = step_config['inputs'].reduce({}, :merge)
            cmd_step << load_workflow_step(step_key, step_inputs)
          end
        end
      end

      def load_workflow_step(step_key, step_inputs)
        step_key_normalized = normalize_step_key(step_key)

        # Translate step with normalized key (for translator) and its input configuration
        @translator.translate_step(step_key_normalized, step_inputs)
      end

      def normalize_step_key(step_key)
        step_key.split('@').first
      end
    end
  end
end
