# frozen_string_literal: true

module BK
  module Compat
    # Bitrise workflow configuration loader
    class Bitrise
      def load_workflow(key, config)
        raise "Duplicate workflow name: #{key}" if @steps_by_key.include?(key)

        @steps_by_key[key] = load_workflow_steps(key, config)
      end

      def load_workflow_steps(key, config)
        # Extend for other types of steps - approvals/waits for example.
        BK::Compat::CommandStep.new(label: key, key: key).tap do |cmd_step|
          config['steps'].each do |step|
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
