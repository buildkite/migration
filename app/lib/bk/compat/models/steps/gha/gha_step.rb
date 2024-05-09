# frozen_string_literal: true

module BK
  module Compat
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
