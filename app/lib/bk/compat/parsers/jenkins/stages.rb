# frozen_string_literal: true

require_relative '../../models/steps/command'

module BK
  module Compat
    # Jenkins YAML converter
    class Jenkins
      private

      def translate_stage(stage, default_step)
        default_step = CommandStep.new if default_step.nil?
        cmd = default_step.instantiate
        cmd.key = stage['stage']
        cmd.env.update(stage.fetch('environment', {}))

        translate_stage_keys(cmd, stage)
      end

      def translate_stage_keys(cmd, stage)
        cmd.tap do |c|
          c << translate_agent(stage['agent'])
          c << translate_options(stage['options'])
          c << translate_steps(stage['steps'])
        end
      end

      def translate_steps(steps)
        case steps
        when String
          steps.split("\n")
        when Array
          steps
        when Hash
          translate_script(steps['script'])
        else
          []
        end
      end

      def translate_script(script)
        return script.split("\n") if script.is_a?(String)

        # if not a string, assume it is an array
        script.prepend(CommandStep.new).reduce do |base, elem|
          base << translate_script_element(elem)
        end
      end

      def translate_script_element(elem)
        return elem if elem.is_a?(String)

        # if not a string, it is a hash with a script element
        CommandStep.new.tap do |cmd|
          cmd << translate_script(elem['script'])
          cmd.prepend_commands('# Credentials must be configured separately') if elem.include?('withCredentials')

          # If a directory is specified, wrap the command in a `cd` block
          if elem.include?('dir')
            cmd.prepend_commands("( cd #{elem['dir']}")
            cmd.add_commands(')')
          end

          cmd.env.update(translate_script_withEnv(elem['withEnv']))
        end
      end

      def translate_script_withEnv(env_string)
        # TODO: implement a proper translation for withEnv
        {var: env_string}
      end
    end
  end
end
