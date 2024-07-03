# frozen_string_literal: true

require 'active_support//core_ext/object/blank'

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        VALID_STEP_TYPES = %w[change-workdir git-clone script].freeze

        def matcher(type, _config)
          VALID_STEP_TYPES.include?(type.downcase)
        end

        def translator(type, config)
          send("translate_#{type.downcase.gsub('-', '_')}", config)
        end

        def translate_change_workdir(config)
          [
            generate_change_workdir_command(config['path'], config['is_create_path'])
          ]
        end

        def generate_change_workdir_command(path, is_create_path)
          if is_create_path && path.present?
            "mkdir #{path} && cd #{path}"
          elsif !is_create_path && path.present?
            "cd #{path}"
          else
            '# Invalid change-workdir step configuration!'
          end
        end

        def translate_git_clone(_config)
          [
            ['# No need for cloning, the agent takes care of that']
          ]
        end

        def translate_script(config)
          [
            config['inputs'].first['content']
          ]
        end
      end
    end
  end
end
