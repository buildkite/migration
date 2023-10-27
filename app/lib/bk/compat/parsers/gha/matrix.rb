# frozen_string_literal: true

module BK
  module Compat
    class GitHubActions
      def set_matrix(bk_step, config)
        matrix = config['strategy']['matrix'].transform_values(&:to_s)
        bk_step.matrix = {
          'setup' => matrix,
          'adjustments' => []
        }
      end
    end
  end
end
