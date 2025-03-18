# frozen_string_literal: true

module BK
  module Compat
    # Bitrise translation of workflows
    class Bitrise
      private

      # Processes each workflow step
      # @param step [Hash] step configuration
      # @return [Array] step key and inputs
      def process_step(step)
        step_key, step_config = step.first
        step_inputs = extract_inputs(step_config)
        step_stack = step_config.fetch('stack', nil)

        [step_key, step_inputs, step_stack]
      end

      # Extracts inputs from step configuration
      # @param step_config [Hash] step configuration
      # @return [Hash] processed inputs
      def extract_inputs(step_config)
        return {} unless step_config['inputs']

        if step_config['inputs'].is_a?(Array)
          step_config['inputs'].reduce({}, :merge)
        else
          step_config['inputs']
        end
      end

      # Process all steps and add them to the command step
      # @param cmd_step [CommandStep] the command step to add to
      # @param steps [Array] workflow steps to process
      def add_workflow_steps(cmd_step, steps)
        steps.each do |step|
          step_key, step_inputs, step_stack = process_step(step)

          translated_step = load_workflow_step(step_key, step_inputs)
          # Only set stack if the translated step is an object that responds to stack=
          translated_step.stack = step_stack if step_stack && translated_step.respond_to?(:stack=)
          cmd_step << translated_step
        end
      end

      def parse_workflow(wf_name, wf_config)
        workflow_stack = wf_config.fetch('stack', nil)

        BK::Compat::CommandStep.new(label: wf_name, key: wf_name).tap do |cmd_step|
          cmd_step.stack = workflow_stack if workflow_stack
          return cmd_step unless wf_config['steps']

          add_workflow_steps(cmd_step, wf_config['steps'])
        end
      end

      def load_workflow_step(step_key, step_inputs)
        step_key_normalized = normalize_step_key(step_key)
        @translator.translate_step(step_key_normalized, step_inputs)
      end

      def normalize_step_key(step_key)
        step_key.split('@').first
      end
    end
  end
end
