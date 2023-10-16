# frozen_string_literal: true

module BK
  module Compat
    class GitHubActions
      def set_matrix(bk_step, config)
        matrix = normalize_matrix(config['strategy'])
        bk_step.matrix = {
          'setup' => matrix,
          'adjustments' => []
        }
      end

      def normalize_matrix(strategy)
        case strategy
        when Hash
          strategy['matrix']
        else
          raise TypeError
        end
      end
    end
  end
end
