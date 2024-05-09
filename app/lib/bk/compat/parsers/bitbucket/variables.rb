# frozen_string_literal: true

require_relative '../../pipeline/step'
require_relative '../../pipeline/plugin'

module BK
  module Compat
    module BitBucketSteps
      # Implementation of native step translation
      class Variables
        def matcher(conf, *, **)
          conf.include?('variables')
        end

        def translator(conf, *, **)
          # TODO: only parse variables on custom pipelines
          # TODO: variables apparently are only one per pipeline
          # TODO: replace variables defined with metadata gets
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
