# frozen_string_literal: true

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

      def to_h
        @group = @label unless @label.nil?
        @label = nil
        @steps = @steps.map(&:to_h)

        super
      end
    end
  end
end
