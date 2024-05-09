# frozen_string_literal: true

module BK
  module Compat
    class WaitStep
      def to_h
        'wait'
      end

      def <<(_obj)
        raise 'Can not add to a wait step'
      end

      def instantiate
        dup
      end
    end
  end
end
    