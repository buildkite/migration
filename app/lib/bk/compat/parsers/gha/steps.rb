# frozen_string_literal: true

module BK
  module Compat
    # Implement GHA Builtin Steps
    class GHABuiltins
      def initialize(register:)
        register.call(
          ->(conf) { conf.include?('run') },
          method(:translate_run)
        )

        register.call(
          ->(conf) { conf.include?('uses') },
          method(:translate_uses)
        )
      end

      private

      def translate_run(step)
        [
          step.include?('name') ? "echo '~~~ #{step['name']}'" : nil,
          step.include?('shell') ? '# Shell is determined in the agent' : nil,
          step.include?('timeout-minutes') ? '# timeouts are per-job, not step' : nil,
          generate_command_string(
            commands: step['run'],
            env: step.fetch('env', {}),
            workdir: step['working-directory']
          )
        ].flatten.compact
      end

      def translate_uses(step)
        case step['uses']
        when /\Aactions\/setup-python@v\d+\z/
          python_version = step.dig('with', 'python-version') || 'latest'
          image_string = "python:#{python_version}"
          BK::Compat::Plugin.new(
            name: 'docker',
            config: {
              'image' => image_string
            }
          )
        when /docker\/login-action.*/
          BK::Compat::Plugin.new(
            name: 'docker-login',
            config: {
              'username' => step['with']['username'],
              'password-env' => step['with']['password'],
            }
          ) 
        when /\Aactions\/upload-artifact@v\d+\z/  
          BK::Compat::ArtifactPaths.new(
            paths: step['with']['path'] 
          ) 
        when /\Aactions\/checkout@v\d+\z/
          "# action #{step['uses']} is not necessary in Buildkite"
        else
          "# action #{step['uses']} can not be translated just yet"
        end
      end

      def generate_command_string(commands: [], env: {}, workdir: nil)
        vars = env.map { |k, v| "#{k}=\"#{v}\"" }
        avoid_parens = vars.empty? && workdir.nil?
        [
          avoid_parens ? nil : '(',
          workdir.nil? ? nil : "cd '#{workdir}'",
          vars.empty? ? nil : vars,
          commands.lines(chomp: true),
          avoid_parens ? nil : ')'
        ].compact
      end
    end

    # wrapper class to setup parameters
    class GHAStep < BK::Compat::CommandStep
      def initialize(*, **)
        super
        @transformer = method(:gha_params)
      end

      EXPRESSION_REGEXP = /\${{\s*(?<data>.*)\s*}}/

      def gha_params(value)
        value.gsub(EXPRESSION_REGEXP) do |v|
          d = EXPRESSION_REGEXP.match(v)
          replace_params(d[:data])
        end
      end

      def replace_params(str)
        context, rest = str.split('.', 2)
        send("replace_context_#{context}", rest)
      rescue NoMethodError
        "Context element #{str} can not be translated (yet)"
      end

      def replace_context_env(var_name)
        # env context get mapped to environment variables
        "$#{var_name}"
      end

      def replace_context_vars(var_name)
        # env context get mapped to environment variables
        "$#{var_name}"
      end

      def replace_context_needs(path)
        job, context, *rest = path.split('.')
        case context
        when 'results'
          # return values are not the same, but it is a rough equivalent
          "$(buildkite-agent step get outcome --step '#{job}')"
        when 'outputs'
          replace_context_needs_outputs(job, rest)
        end
      end

      def replace_context_needs_outputs(job, path_list)
        if path_list.empty?
          # format of the resulting output is probably not the same
          "$(for KEY in $(buildkite-agent meta-data list | grep '^#{job}.')) do" \
            'buildkite-agent meta-data get "$KEY"; end)'
        elsif path_list.one?
          "$(buildkite-agent meta-data get '#{job}.#{path_list[0]}')"
        else
          "#{path_list} does not appear to be a valid step output"
        end
      end
    end
  end
end
