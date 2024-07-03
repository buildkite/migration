# frozen_string_literal: true

module BK
  module Compat
    # Bitrise translation of workflows
    class Bitrise
      private

      def parse_workflow(wf_name, _wf_config)
        raise "No key within loaded workflow configuration for #{wf_name}" unless @steps_by_key.include?(wf_name)

        @steps_by_key[wf_name]
      end
    end
  end
end
