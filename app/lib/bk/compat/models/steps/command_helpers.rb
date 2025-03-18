# frozen_string_literal: true

module BK
  module Compat
    # Helper methods for CommandStep to reduce class size
    module CommandHelpers
      def instantiate(*, **)
        unless @transformer.nil?
          params = instance_attributes.transform_values { |val| recurse_to_string(val, @transformer.to_proc, *, **) }
        end
        params.delete(:parameters)

        self.class.new(**params)
      end

      def recurse_to_string(value, block, *, **)
        case value
        when String
          block.call(value, *, **)
        when Hash
          value.transform_values! { |elem| recurse_to_string(elem, block, *, **) }
        when Array
          value.map! { |elem| recurse_to_string(elem, block, *, **) }
        else
          # if we don't know how to do this, do nothing
          value
        end
      end
    end
  end
end
