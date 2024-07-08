# frozen_string_literal: true

require_relative 'base'

module BK
  module Compat
    # simple block step
    class BlockStep < BaseStep
      attr_accessor :conditional, :depends_on, :fields, :key, :label, :prompt

      def list_attributes
        %w[depends_on fields].freeze
      end

      def <<(_other)
        raise 'Can not add to a block step'
      end

      def >>(_other)
        raise 'Can not add to a block step'
      end

      def to_h
        @block = @key
        super
      end
    end
  end
end
