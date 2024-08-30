# frozen_string_literal: true

require_relative 'base'

module BK
  module Compat
    # group step
    class GroupStep < BaseStep
      attr_accessor :depends_on, :key, :label, :steps, :conditional

      def list_attributes
        %w[depends_on steps].freeze
      end

      def initialize(*, **kwargs)
        # ensure label has a ~ default value
        repack = { label: '~' }.merge(kwargs)
        super(*, **repack)
      end

      def simplify
        return super unless steps.one?

        @steps.pop.tap do |s|
          s.conditional = conditional
          s.key = [@key, s.key].compact.join('-')
          s.label = [@label, s.label].compact.join(' ')
        end
      end

      def to_h
        @group = @label unless @label.nil?
        @label = nil
        @steps = @steps.map(&:to_h)

        super
      end
    end
  end
end
