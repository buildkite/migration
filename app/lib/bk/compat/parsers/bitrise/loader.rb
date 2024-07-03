# frozen_string_literal: true

module BK
  module Compat
    # Bitrise configuration loader
    class Bitrise
      def load_workflow(key, config)
        load_workflow_steps(key, config)
      end

      def load_workflow_steps(key, config)
        cmds = []
        config['steps'].each do |step| 
          step_key, step_config = step.first
          step_key_normalized = normalize_step_type(step_key)
          cmd = @translator.translate_step(step_key_normalized, step_config)
        end
      end

      def normalize_step_key(step)
        # Pull out the step type without its version to match translator's supported steps
        step.match?(STEP_TYPE_REGEX) ? step.match(STEP_TYPE_REGEX)[1] : step
      end
    end
  end
end
