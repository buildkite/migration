# frozen_string_literal: true

require_relative 'block'

module BK
  module Compat
    # input steps are almost the same as block steps (difference is dependency semantics)
    class InputStep < BlockStep
      def to_h
        super.tap do |h|
          h[:input] = h.delete(:block)
        end
      end
    end
  end
end  