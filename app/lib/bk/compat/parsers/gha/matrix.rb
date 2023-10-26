# frozen_string_literal: true

module BK
  module Compat
    class GitHubActions
      def set_matrix(bk_step, config)
        matrix = config['strategy']['matrix']
        matrix.map { |key, value| [key, value.map(&:to_s)] }.to_h
        bk_step.matrix = {
          'setup' => matrix,
          'adjustments' => []
        }
      end
    end
  end
end
