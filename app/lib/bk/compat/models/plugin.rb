# frozen_string_literal: true

module BK
  module Compat
    DEFAULT_VERSIONS = {
      'docker' => 'v5.10.0',
      'docker-compose' => 'v5.0.0',
      'docker-login' => 'v3.0.0',
      'ecr' => 'v2.7.0'
    }.to_h do |p, v|
      env_friendly = p.upcase.tr('^A-Z0-9', '_')
      [p, ENV.fetch("BUILDKITE_PLUGIN_#{env_friendly}_VERSION", v)]
    end.freeze

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
