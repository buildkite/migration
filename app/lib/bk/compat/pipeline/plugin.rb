# frozen_string_literal: true

module BK
  module Compat
    DEFAULT_VERSIONS = {
      'docker' => 'v5.7.0',
      'docker-compose' => 'v4.14.0',
      'docker-login' => 'v2.1.0',
      'ecr' => 'v2.7.0'
    }.freeze

    # Plugin to use in a step
    class Plugin
      def initialize(name:, version: nil, config: nil)
        @name = name
        @version = version
        @config = config
      end

      def path
        base = @name
        version = @version || DEFAULT_VERSIONS.fetch(@name, nil)
        base += "##{version}" unless version.nil?

        base
      end

      def to_h
        { path => @config }
      end
    end
  end
end
