# frozen_string_literal: true

require_relative '../../pipeline/step'

module BK
  module Compat
    # Translate matrix configurations
    class GitHubActions
      def generate_matrix(matrix)
        return {} if matrix.nil?

        # first delete the keys that are extra configurations (if present)
        inc = matrix.delete('include') || []
        exc = matrix.delete('exclude') || []

        {
          setup: convert_to_string(matrix),
          adjustments: generate_inclusions(matrix, inc) + generate_exclusions(matrix, exc)
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

      def generate_exclusions(_matrix, exclusions)
        exclusions.map do |comb|
          {
            with: convert_to_string(comb),
            skip: true
          }
        end
      end

      def generate_inclusions(_matrix, inclusions)
        # translation is simple but resulting adjustment will be invalid
        # if inclusions have new keys not in matrix
        # or are missing any keys
        inclusions.map do |comb|
          { with: convert_to_string(comb) }
        end
      end
    end
  end
end
