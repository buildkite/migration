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
          validate_brew_install_command(inputs)
        end

        def translate_bundler(inputs)
          return '# Invalid bundler step configuration!' unless required_bundler_inputs(inputs)

          install_jobs = inputs['bundle_install_jobs']
          install_retry = inputs['bundle_install_retry']

          "bundle check || bundle install --jobs #{install_jobs} --retry #{install_retry}"
        end

        def required_bundler_inputs(inputs)
          inputs.include?('bundle_install_jobs') && inputs.include?('bundle_install_retry')
        end

        def translate_change_workdir(inputs)
          return '# Invalid change-workdir step configuration!' unless inputs.include?('path')

          [
            inputs['is_create_path'] ? "mkdir #{inputs['path']}" : nil,
            "cd #{inputs['path']}"
          ].compact
        end

        def translate_git_clone(_inputs)
          '# No need for cloning, the agent takes care of that'
        end

        def translate_git_tag(inputs)
          return '# Invalid git-tag step configuration!' unless inputs.include?('tag')

          cmd_all_params = "git tag -fa #{inputs['tag']} -m #{inputs['tag_message']}"
          cmd_no_message = "git tag -fa #{inputs['tag']}"

          [
            inputs['tag_message'].nil? ? cmd_no_message : cmd_all_params,
            !inputs['push'].nil? && inputs['push'] ? 'git push --tags' : nil
          ].compact
        end

        def translate_script(inputs)
          inputs['content']
        end
      end
    end
  end
end
