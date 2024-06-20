# frozen_string_literal: true

module BK
  module Compat
    # Shared behaviour among steps
    class BaseStep
      def list_attributes
        []
      end

      def hash_attributes
        []
      end

      def initialize(**kwargs)
        # nil as default are not acceptable
        list_attributes.each { |k| send("#{k}=", []) }
        hash_attributes.each { |k| send("#{k}=", {}) }

        kwargs.map do |k, v|
          # set attributes passed through as-is
          send("#{k}=", v)
        end
      end

      private

      def key_order
        %i[group block key label depends_on if agent commands].freeze
      end

      def _order(key)
        # helper method to get keys in a particular order
        key_order.index(key) || key_order.length
      end

      def instantiate
        dup
      end

      def instance_attributes
        # helper method to get all instance attributes as a dictionary
        instance_variables.to_h { |v| [v.to_s.delete_prefix('@').to_sym, instance_variable_get(v)] }
      end

      def to_h
        h = instance_attributes
        # rename conditional to if (a reserved word as an attribute or instance variable is complicated)
        h[:if] = h.delete(:conditional)

        clean_dict(h)
      end

      def clean_dict(dict)
        # remove empty and nil values
        dict.delete_if { |_, v| v.nil? || ((v.is_a?(Enumerable) || v.is_a?(String)) && v.empty?) }

        # sort values for stable and consistent outputs
        dict.sort { |a, b| _order(a[0]) - _order(b[0]) }.to_h
      end
    end
  end
end
