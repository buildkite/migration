# frozen_string_literal: true

require_relative 'base'

module BK
  module Compat
    # simple waiting step
    class WaitStep < BaseStep
      def to_h
        'wait'
      end

      def <<(_other)
        raise 'Can not add to a wait step'
      end

      def >>(_other)
        raise 'Can not add to a wait step'
      end
    end
  end
end
