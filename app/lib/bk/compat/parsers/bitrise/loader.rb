# frozen_string_literal: true

module BK
  module Compat
    # Bitrise workflow configuration loader
    class Bitrise
      STEP_KEY_REGEX = /([a-zA-Z-]*)@(\d*|0)(\.((\d*)|0)){0,3}/

      def load_workflow(key, config)
        raise "Duplicate workflow name: #{key}" if @steps_by_key.include?(key)

        @steps_by_key[key] = load_workflow_steps(config)
      end

      def load_workflow_steps(config)
        # Extend for other types of steps - approvals/waits for example.
        BK::Compat::CommandStep.new.tap do |cmd_step|
          config['steps'].each do |step|
            step_key, step_config = step.first
            step_inputs = step_config['inputs'].reduce({}, :merge)
            cmd_step.commands << load_workflow_step(step_key, step_inputs)
          end
        end
      end

      def load_workflow_step(step_key, step_inputs)
        step_key_normalized = normalize_step_key(step_key)

        # Translate step with normalized key (for translator) and its input configuration
        @translator.translate_step(step_key_normalized, step_inputs)
      end

      def normalize_step_key(step_key)
        # Pull out the step key without its version to match translator's supported steps
        step_key.match?(STEP_KEY_REGEX) ? step_key.match(STEP_KEY_REGEX)[1] : step_key
      end
    end
  end
end
