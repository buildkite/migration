# frozen_string_literal: true

module BK
  module Compat
    # Dispatch pattern for step translation
    module StepTranslator
      def register_translator(matcher, function)
        @translators ||= [] # utilize an instance variable that may not exist

        @translators << { matcher: matcher, function: function }
      end

      def translate_step(step_key, config, *args)
        @translators ||= [] # utilize an instance variable that may not exist

        result = @translators.select { |translator| generic_matcher?(translator[:matcher], step_key) }
                             .map { |translator| translator[:function]&.call(step_key, config, *args) }
                             .flatten

        return [" # step #{step_key} not implemented yet :("] if result.empty?

        result
      end

      private

      def generic_matcher?(matcher, step_key)
        case matcher
        when Regexp
          matcher.match?(step_key)
        when Array
          matcher.include?(step_key)
        when Proc, Method
          matcher.call(step_key)
        else
          matcher == step_key
        end
      end
    end
  end
end
