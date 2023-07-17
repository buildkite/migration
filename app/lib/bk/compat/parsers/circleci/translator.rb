# frozen_string_literal: true

module BK
  module Compat
    # Dispatch pattern for step translation
    module StepTranslator
      def register_step(key, function)
        @known_steps ||= {} # utilize an instance variable that may not exist

        raise ArgumentError, "A translator for #{key} already exists" if @known_steps[key]

        @known_steps[key] = function
      end

      def translate_step(step_key, config, *args)
        @known_steps ||= {} # utilize an instance variable that may not exist

        translator = @known_steps[step_key]
        translator&.call(config, *args) || [" # #{step_key} not supported (yet)"]
      end
    end
  end
end
