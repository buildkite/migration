# frozen_string_literal: true

require_relative 'commands'

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        VALID_STEP_TYPES = %w[bundler brew-install change-workdir git-clone git-tag script].freeze

        def matcher(type, _inputs)
          VALID_STEP_TYPES.include?(type.downcase)
        end

        def translator(type, inputs)
          send("translate_#{type.downcase.gsub('-', '_')}", inputs)
        end

        def translate_brew_install(inputs)
          [
            validate_brew_install_command(inputs)
          ]
        end

        def translate_bundler(inputs)
          [
            generate_bundler_command(inputs)
          ]
        end

        def translate_change_workdir(inputs)
          [
            generate_change_workdir_command(inputs['path'], inputs['is_create_path'])
          ]
        end

        def translate_git_clone(_inputs)
          [
            ['# No need for cloning, the agent takes care of that']
          ]
        end

        def translate_git_tag(inputs)
          [
            generate_git_tag_command(inputs)
          ]
        end

        def translate_script(inputs)
          [
            inputs['content']
          ]
        end
      end
    end
  end
end
