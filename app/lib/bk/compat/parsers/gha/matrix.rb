# frozen_string_literal: true

require_relative '../../pipeline/step'

module BK
  module Compat
    class GitHubActions
      def set_matrix(bk_step, config)
        matrix = convert_to_string(config['strategy']['matrix'])
        bk_step.matrix = {
          'setup' => matrix,
          'adjustments' => []
        }
      end

      def convert_to_string(value)
        case value
        when Hash
          value.transform_values! { |elem| convert_to_string(elem) }
        when Array
          value.map! { |elem| convert_to_string(elem) }
        when Numeric
          "#{value}"
        else
          # if we don't know how to do this, do nothing
          value
        end
      end
    end
  end
end
