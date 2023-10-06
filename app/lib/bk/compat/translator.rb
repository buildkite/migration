# frozen_string_literal: true

module BK
  module Compat
    # Dispatch pattern for step translation
    module StepTranslator
      def register_translator(matcher, function)
        @translators ||= [] # utilize an instance variable that may not exist

        @translators << { matcher: matcher, function: function }
      end

      def translate_step(*, **)
        @translators ||= [] # utilize an instance variable that may not exist

        result = @translators.select { |translator| translator[:matcher]&.call(*, **) }
                             .map { |translator| translator[:function]&.call(*, **) }

        simplify_result(result.flatten, *, **)
      end

      def simplify_result(result_list, *args, **kwargs)
        return [" # step #{args} #{kwargs} not implemented yet :("] if result_list.empty?

        result_list = result_list.first if result_list.one?
        result_list
      end
    end
  end
end
