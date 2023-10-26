# frozen_string_literal: true

require_relative 'expressions'
require_relative 'uses/setup-java'

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
        when /\Aactions\/setup-java@v\d+\z/
          java_version = step.dig('with', 'java-version') || '21'
          distribution = step.dig('with', 'distribution') || 'temurin'
          image_string = obtain_java_distribution_image(distribution, java_version)
          BK::Compat::Plugin.new(
            name: 'docker',
            config: {
              'image' => image_string
            }
          )
        when /\Aactions\/setup-go@v\d+\z/
          go_version = step.dig('with', 'go-version').gsub!(/[>=^]/,'') || 'latest'
          image_string = "golang:#{go_version}"
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
      EXPRESSION_TRANSFORMER = BK::Compat::GithubExpressions.new

      def gha_params(value)
        value.gsub(EXPRESSION_REGEXP) do |v|
          d = EXPRESSION_REGEXP.match(v)
          EXPRESSION_TRANSFORMER.transform(d[:data])
        end
      end
    end
  end
end
