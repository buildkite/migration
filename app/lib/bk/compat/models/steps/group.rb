# frozen_string_literal: true

module BK
  module Compat
    class GroupStep
      attr_accessor :label, :key, :steps, :depends_on, :conditional
  
      def initialize(label: '~', key: nil, steps: [], depends_on: [], conditional: nil)
        @label = label
        @key = key
        @depends_on = depends_on
        @steps = steps
        @conditional = conditional
      end
  
      def to_h
        { group: @label, key: @key, steps: @steps.map(&:to_h) }.tap do |h|
          h[:depends_on] = @depends_on unless @depends_on.empty?
          h[:if] = @conditional unless @conditional.nil?
        end.compact
      end
    end
  end
end
  