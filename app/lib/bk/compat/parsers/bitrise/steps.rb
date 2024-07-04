# frozen_string_literal: true

require 'active_support//core_ext/object/blank'

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        VALID_STEP_TYPES = %w[bundler brew-install change-workdir git-clone script].freeze

        def matcher(type, _inputs)
          VALID_STEP_TYPES.include?(type.downcase)
        end

        def translator(type, inputs)
          send("translate_#{type.downcase.gsub('-', '_')}", inputs)
        end

        def translate_brew_install(inputs)
          [
            generate_brew_install_command(inputs)
          ]
        end

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

        def translate_bundler(inputs)
          [
            generate_bundler_command(inputs)
          ]
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

        def translate_change_workdir(inputs)
          [
            generate_change_workdir_command(inputs['path'], inputs['is_create_path'])
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

        def translate_git_clone(_inputs)
          [
            ['# No need for cloning, the agent takes care of that']
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
