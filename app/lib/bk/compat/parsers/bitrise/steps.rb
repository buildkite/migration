# frozen_string_literal: true

require 'active_support//core_ext/object/blank'

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        VALID_STEP_TYPES = %w[change-workdir git-clone script].freeze

        def matcher(type, _inputs)
          VALID_STEP_TYPES.include?(type.downcase)
        end

        def translator(type, inputs)
          send("translate_#{type.downcase.gsub('-', '_')}", inputs)
        end

        def translate_change_workdir(inputs)
          generate_change_workdir_command(inputs)
        end

        def generate_change_workdir_command(inputs)
          return '# Invalid change-workdir step configuration!' unless inputs.include?('path')
          
          [
            inputs['is_create_path'] ? "mkdir #{inputs['path']}" : nil,
            "cd #{inputs['path']}"
          ].compact
        end

        def translate_git_clone(_inputs)
          '# No need for cloning, the agent takes care of that'
        end

        def translate_script(inputs)
          inputs['content']
        end
      end
    end
  end
end
