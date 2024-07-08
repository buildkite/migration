# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Implementation of Bitrise step translations
      class Translator
        def validate_brew_install_command(inputs)
          return '# Invalid brew-install configuration!' unless inputs.include?('verbose_log')

          generate_brew_install_command(inputs)
        end

        def generate_brew_install_command(inputs)
          if !inputs['packages'].nil?
            generate_brew_install_package_command(inputs)
          elsif inputs['use_brewfile'] && !inputs['brewfile_path'].nil?
            generate_brew_bundle_command(inputs)
          else
            # verbose_log defined, packages and use_brewfile/brewfile_path not defined - invalid
            '# Invalid brew-install configuration!'
          end
        end

        def generate_brew_install_package_command(inputs)
          cmd_reinstall = "brew reinstall#{inputs['verbose_log'] ? ' -vd' : nil} #{inputs['packages']}"
          cmd_install = "brew install#{inputs['verbose_log'] ? ' -vd' : nil} #{inputs['packages']}"

          inputs['upgrade'] ? cmd_reinstall : cmd_install
        end

        def generate_brew_bundle_command(inputs)
          "brew bundle#{inputs['verbose_log'] ? ' -vd' : nil} --file=#{inputs['brewfile_path']}"
        end

        def generate_bundler_command(inputs)
          return '# Invalid bundler step configuration!' unless required_bundler_inputs(inputs)

          install_jobs = inputs['bundle_install_jobs']
          install_retry = inputs['bundle_install_retry']

          "bundle check || bundle install --jobs #{install_jobs} --retry #{install_retry}"
        end

        def required_bundler_inputs(inputs)
          inputs.include?('bundle_install_jobs') && inputs.include?('bundle_install_retry')
        end

        def generate_change_workdir_command(inputs)
          return '# Invalid change-workdir step configuration!' unless inputs.include?('path')

          [
            inputs['is_create_path'] ? "mkdir #{inputs['path']}" : nil,
            "cd #{inputs['path']}"
          ].compact
        end

        def generate_git_tag_command(inputs)
          return '# Invalid git-tag step configuration!' unless inputs.include?('tag')

          cmd_all_params = "git tag -fa #{inputs['tag']} -m #{inputs['tag_message']}"
          cmd_no_message = "git tag -fa #{inputs['tag']}"

          [
            inputs['tag_message'].nil? ? cmd_no_message : cmd_all_params,
            !inputs['push'].nil? && inputs['push'] ? 'git push --tags' : nil
          ].compact
        end
      end
    end
  end
end
