# frozen_string_literal: true

require 'active_support//core_ext/object/blank'

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        def generate_brew_install_command(inputs)
          if inputs['packages'].present? && inputs['upgrade']
            "brew reinstall #{inputs['packages']}"
          elsif inputs['packages'].present? && !inputs['upgrade']
            "brew install #{inputs['packages']}"
          elsif inputs['use_brewfile'].present?
            'brew bundle'
          else
            'brew install'
          end
        end

        def generate_bundler_command(inputs)
          install_jobs = inputs['bundle_install_jobs']
          install_retry = inputs['bundle_install_retry']

          if install_jobs.present? && install_retry.present?
            "bundle check || bundle install --jobs #{install_jobs} --retry #{install_retry}"
          else
            '# Invalid bundler step configuration!'
          end
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

        def generate_git_tag_command(inputs)
          cmd_all_params = "git tag -fa #{inputs['tag']} -m #{inputs['tag_message']} && git push --tags"
          cmd_no_message = "git tag -fa #{inputs['tag']} && git push --tags"

          if inputs['tag'].present? && inputs['push'].present?
            inputs['tag_message'].present? ? cmd_all_params : cmd_no_message
          else
            '# Invalid git-tag step configuration!'
          end
        end
      end
    end
  end
end
