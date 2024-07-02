# frozen_string_literal: true

module BK
  module Compat
    # Bitrise translation of workflows
    class Bitrise
      STEP_TYPE_REGEX = /([a-zA-Z]*)@(\d*|0)(\.((\d*)|0)){0,3}/

      private

      def parse_workflow(wf_name, wf_config)
        BK::Compat::GroupStep.new(
          label: ":bitrise: #{wf_name}",
          key: wf_name,
          steps: parse_workflow_steps(wf_config)
        )
      end

      def parse_workflow_steps(wf_config)
        cmds = []
        wf_config['steps'].each do |step|
          step_key = step.first.first
          step_conf = step[step.first.first]
          key_normalized = normalize_step_type(step_key)
          cmds << @translator.translate_step(key_normalized, step_conf)
        end
        cmds
      end

      def normalize_step_type(step)
        step.match?(STEP_TYPE_REGEX) ? step.match(STEP_TYPE_REGEX)[1] : step
      end
    end
  end
end
