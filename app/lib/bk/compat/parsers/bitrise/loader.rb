# frozen_string_literal: true

module BK
  module Compat
    # Bitrise workflow configuration loader
    class Bitrise
      STEP_KEY_REGEX = /([a-zA-Z-]*)@(\d*|0)(\.((\d*)|0)){0,3}/

      def load_workflow(key, config)
        raise "Duplicate workflow name: #{key}" if @steps_by_key.include?(key)

        @steps_by_key[key] = load_workflow_steps(key, config)
      end

      def load_workflow_steps(key, config)
        BK::Compat::CommandStep.new(label: key, key: key).tap do |cmd_step|
          config['steps'].each do |step|
            step_key, step_config = step.first
            cmd_step.commands << load_workflow_step(step_key, step_config)
          end
        end
      end

      def load_workflow_step(step_key, step_config)
        step_key_normalized = normalize_step_key(step_key)

        # Translate step with normalized key (for translator) and its configuration
        @translator.translate_step(step_key_normalized, step_config)
      end

      def normalize_step_key(step_key)
        # Pull out the step key without its version to match translator's supported steps
        step_key.match?(STEP_KEY_REGEX) ? step_key.match(STEP_KEY_REGEX)[1] : step_key
      end
    end
  end
end
