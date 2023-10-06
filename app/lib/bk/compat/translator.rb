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
                             .flatten

        return [" # step #{step_key} not implemented yet :("] if result.empty?

        result
      end
    end
  end
end
