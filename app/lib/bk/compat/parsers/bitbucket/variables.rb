# frozen_string_literal: true

require_relative '../../pipeline/step'
require_relative '../../pipeline/plugin'

module BK
  module Compat
    module BitBucketSteps
      # Implementation of native step translation
      class Variables
        def initialize(register:)
          register.call(
            method(:matcher),
            method(:translator)
          )
        end

        private

        def matcher(conf, *, **)
          conf.include?('variables')
        end

        def translator(conf, *, **)
          BK::Compat::InputStep.new(
            key: 'custom-vars',
            fields: conf['variables'].map do |var|
              {
                'key' => var['name'],
                'default' => var.delete('default')
              }.tap do |h|
                h['options'] = var['allowed-values']&.map { |x| { 'label' => x, 'value' => x } }
                type = var.fetch('allowed-values', []).empty? ? 'text' : 'select'

                h[type] = var.fetch('description', h['key'])
              end.compact
            end
          )
        end
      end
    end
  end
end
