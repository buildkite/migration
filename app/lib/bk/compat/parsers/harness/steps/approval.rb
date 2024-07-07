# frozen_string_literal: true

require_relative '../../../models/steps/block'

module BK
  module Compat
    module HarnessSteps
      # Implementation of native step translation
      class Translator
        private

        def translate_harnessapproval(name:, identifier:, spec:, **_rest)
          BK::Compat::BlockStep.new(
            label: name,
            key: identifier,
            prompt: spec.fetch('approvalMessage', nil),
            fields: spec.fetch('approverInputs', []).map do |e|
              { 'key' => e['name'], 'text' => "Default #{e['defaultValue']}" }
            end
          )
        end
      end
    end
  end
end
