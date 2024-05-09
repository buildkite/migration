# frozen_string_literal: true

require_relative 'block'

module BK
  module Compat
    # input steps are almost the same as block steps
    class InputStep < BlockStep
      attr_accessor :fields

      def initialize(*, fields: nil, **)
        super(*, **)
        @fields = fields
      end

      def to_h
        super.tap do |h|
          h[:fields] = @fields unless @fields.nil?
          h[:input] = h.delete(:block)
        end
      end
    end
  end
end
  