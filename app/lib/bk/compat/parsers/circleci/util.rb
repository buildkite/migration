# frozen_string_literal: true

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private


      def string_or_list(object)
        object.is_a?(String) ? [object] : object
      end
    end
  end
end
