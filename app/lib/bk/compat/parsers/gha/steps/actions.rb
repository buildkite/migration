# frozen_string_literal: true

module BK
  module Compat
    # Implement GHA actions
    class GHAActions
      def matcher(conf)
        conf.include?('uses')
      end

      def translator(step)
        root, version = step['uses'].split('@')

        # make the action a valid function name
        action = root.gsub(/[^a-zA-Z0-9_]/, '_')
        step['version'] = version # easier access
        send("translate_#{action}", step)
      rescue NoMethodError
        "# action #{step['uses']} can not be translated just yet"
      end

      private

      def translate_actions_checkout(step)
        "# action #{step['uses']} is not necessary in Buildkite"
      end

      def translate_actions_setup_go(step)
        go_version = step.dig('with', 'go-version').gsub(/[>=^]/, '') || 'latest'
        BK::Compat::Plugin.new(
          name: 'docker',
          config: {
            'image' => "golang:#{go_version}"
          }
        )
      end

      def translate_actions_setup_java(step)
        java_version = step.dig('with', 'java-version') || '21'
        distribution = step.dig('with', 'distribution') || 'temurin'

        image_string = obtain_java_distribution_image(distribution, java_version)

        BK::Compat::Plugin.new(
          name: 'docker',
          config: {
            'image' => image_string
          }
        )
      end

      def translate_actions_setup_node(step)
        node_version = step.dig('with', 'node-version') || 'latest'
        match = node_version.match(/(\d+)\.x/)
        node_version = match[1] if match
        image_string = "node:#{node_version}"

        BK::Compat::Plugin.new(
          name: 'docker',
          config: {
            'image' => image_string
          }
        )
      end

      def translate_actions_setup_python(step)
        python_version = step.dig('with', 'python-version') || 'latest'
        BK::Compat::Plugin.new(
          name: 'docker',
          config: {
            'image' => "python:#{python_version}"
          }
        )
      end

      def translate_actions_upload_artifact(step)
        paths = step['with']['path'].lines(chomp: true).map do |path|
          next nil if path.empty? || path.start_with?('!')

          path.end_with?('/') ? "#{path}**/*" : path
        end

        BK::Compat::GHAStep.new(
          artifact_paths: paths.compact
        )
      end

      # Other minor support (if more than a few translate_X, move them to their own file)
      def translate_docker_login_action(step)
        BK::Compat::Plugin.new(
          name: 'docker-login',
          config: {
            'username' => step['with']['username'],
            'password-env' => step['with']['password']
          }
        )
      end

      def obtain_java_distribution_image(distribution, java_version)
        case distribution
        # seemru, adopt-openj9 (moved to semeru)
        when /semeru|adopt-openj9/
          "ibm-semeru-runtimes:open-#{java_version}-jdk"
        # temurin, adpot (moved to temurin), oracle (deprecated)
        when /temurin|adopt|oracle/
          "eclipse-temurin:#{java_version}-jdk-alpine"
        when /zulu/
          "azul/zulu-openjdk-alpine:t#{java_version}-latest"
        when /liberica/
          "bellsoft/liberica-openjdk-alpine:#{java_version}"
        when /microsoft/
          "mcr.microsoft.com/openjdk/jdk:#{java_version}-ubuntu"
        when /coretto/
          "amazoncorretto:#{java_version}-al2023-jdk"
        when /dragonwell/
          "alibabadragonwell/dragonwell:#{java_version}-alpine"
        end
      end
    end
  end
end
