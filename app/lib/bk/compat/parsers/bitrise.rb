# frozen_string_literal: true

require_relative '../translator'
require_relative '../pipeline'
require_relative '../pipeline/step'

require_relative 'bitbucket/import'
require_relative 'bitbucket/parallel'
require_relative 'bitbucket/stages'
require_relative 'bitbucket/steps'
require_relative 'bitbucket/variables'

module BK
  module Compat
    # Bitrise translation scaffolding
    class Bitrise
      require 'yaml'

      def self.name
        'Bitrise'
      end

      def self.option
        'bitrise'
      end

      def self.matches?(text)
        config = YAML.safe_load(text, aliases: true)

        # only required field is pipelines
        mandatory_keys = %w[format_version].freeze

        config.is_a?(Hash) && mandatory_keys & config.keys == mandatory_keys
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text, aliases: true)
        @options = options
      end

      def parse
        Pipeline.new()
      end

    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::Bitrise)
