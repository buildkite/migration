# frozen_string_literal: true

require_relative '../../pipeline/step'

module BK
  module Compat
    # Translate matrix configurations
    class GitHubActions
      def generate_matrix(matrix)
        {
          setup: convert_to_string(matrix),
          adjustments: []
        }
      end

      def convert_to_string(value)
        case value
        when Hash
          value.transform_values! { |elem| convert_to_string(elem) }
        when Array
          value.map! { |elem| convert_to_string(elem) }
        else
          value.to_s
        end
      end
    end
  end
end
