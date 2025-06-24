# frozen_string_literal: true

module BK
  module Compat
    # Dispatch pattern for step translation
    class StepTranslator
      def initialize(default: nil, recursor: nil)
        @default_func = default.nil? ? method(:default_value) : default
        @recursor = recursor || method(:translate_step).to_proc
        @translators = []
      end

      def register(*translators)
        translators.each do |tr|
          # allow translator to have a `recursor` function available
          tr.define_singleton_method(:recursor, @recursor)
          @translators << tr
        end
      end

      def translate_step(*, **)
        # we assume each translator has a matcher and a translator method
        result = @translators.select { |translator| translator.matcher?(*, **) }
                             .map { |translator| translator.translator(*, **) }

        simplify_result(result.flatten, *, **)
      end

      def simplify_result(result_list, *, **)
        return @default_func.call(*, **) if result_list.empty?

        result_list = result_list.first if result_list.one?
        result_list
      end

      def default_value(*args, **kwargs)
        # Default implementation when the translator doesn't know what to do
        [" # step #{args} #{kwargs} not implemented yet :("]
      end
    end
  end
end
