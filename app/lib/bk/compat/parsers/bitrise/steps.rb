# frozen_string_literal: true

require_relative 'github_status'
require_relative 'github_release'
require_relative 'github_last_commit_date'
require_relative 'slack'

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        VALID_STEP_TYPES = %w[
          bundler
          brew-install
          change-workdir
          git-clone
          github-last-commit-date
          github-release
          github-status
          git-tag
          script
          slack
        ].freeze

        def matcher?(type, _inputs)
          VALID_STEP_TYPES.include?(type.downcase)
        end

        def translator(type, inputs)
          send("translate_#{type.downcase.gsub('-', '_')}", inputs)
        end

        def translate_brew_install(inputs)
          return '# Invalid brew-install configuration!' unless inputs.include?('verbose_log')

          generate_brew_install_command(inputs)
        end

        def generate_brew_install_command(inputs)
          if inputs['packages']
            install_type = inputs.fetch('upgrade', false) ? 'reinstall' : 'install'
            "brew #{install_type}#{' -vd' if inputs['verbose_log']} #{inputs['packages']}"
          elsif inputs['use_brewfile'] && inputs['brewfile_path']
            "brew bundle#{' -vd' if inputs['verbose_log']} --file=#{inputs['brewfile_path']}"
          else
            # verbose_log defined, packages and use_brewfile/brewfile_path not defined - invalid
            '# Invalid brew-install configuration!'
          end
        end

        def translate_bundler(inputs)
          return '# Invalid bundler step configuration!' unless required_bundler_inputs?(inputs)

          install_jobs = inputs['bundle_install_jobs']
          install_retry = inputs['bundle_install_retry']

          "bundle check || bundle install --jobs #{install_jobs} --retry #{install_retry}"
        end

        def required_bundler_inputs?(inputs)
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

          [
            "git tag -fa #{inputs['tag']} -m \"#{inputs['tag_message']}\"",
            inputs['push'] ? 'git push --tags' : nil
          ].compact
        end

        def translate_script(inputs)
          inputs['content']
        end
      end
    end
  end
end
