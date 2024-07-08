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
      end
    end
  end
end
