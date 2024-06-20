# frozen_string_literal: true

require_relative '../../../parsers/gha/expressions'

module BK
  module Compat
    # wrapper class to setup parameters
    class GHAStep < CommandStep
      attr_accessor :transformer

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

      def to_h
        @transformer = nil

        super
      end
    end
  end
end
