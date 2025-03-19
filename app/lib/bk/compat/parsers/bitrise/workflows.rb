# frozen_string_literal: true

module BK
  module Compat
    # Bitrise translation of workflows
    class Bitrise
      private

      def parse_workflow(wf_name, wf_config)
        agents = extract_agents(wf_config)
        cmd_step = create_command_step(wf_name, agents)

        wf_config['steps'].each do |step|
          step_key, step_config = step.first
          translated_step = translate_step(step_key, step_config)
          add_step_to_command_step(cmd_step, translated_step)
        end

        cmd_step
      end

      def extract_agents(wf_config)
        wf_config.include?('stack') ? { stack: wf_config['stack'] } : {}
      end

      def create_command_step(wf_name, agents)
        BK::Compat::CommandStep.new(label: wf_name, key: wf_name, agents: agents)
      end

      def translate_step(step_key, step_config)
        step_inputs = extract_step_inputs(step_config)
        translated_step = load_workflow_step(step_key, step_inputs)
        set_agents_for_step(translated_step, step_config)
        translated_step
      end

      def extract_step_inputs(step_config)
        (step_config['inputs'] || {}).reduce({}, :merge)
      end

      def set_agents_for_step(translated_step, step_config)
        translated_step.agents['stack'] = step_config['stack'] if step_config.include?('stack')
      end

      def add_step_to_command_step(cmd_step, translated_step)
        cmd_step << translated_step
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
