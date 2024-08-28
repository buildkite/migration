# frozen_string_literal: true

require_relative '../../../models/steps/command'

module BK
  module Compat
    module HarnessSteps
      # Implementation of native step translation
      class Translator
        def translate_strategy(stg)
          return nil if stg.nil? || stg.empty?

          keys = stg.slice('parallelism', 'matrix', 'repeat')

          raise "Invalid strategy configuration #{stg}" unless keys.length == 1

          key, value = keys.shift

          send("translate_strategy_#{key}", value)
        end

        def translate_strategy_parallelism(conf)
          BK::Compat::CommandStep.new(
            parallelism: conf
          )
        end

        def translate_strategy_matrix(conf)
          concurrency = conf.delete('maxConcurrency')
          adjustments = conf.delete('exclude')&.map { |e| e['skip'] = true }
          BK::Compat::CommandStep.new(
            matrix: {
              setup: conf,
              adjustments: adjustments
            }.compact,
            concurrency: concurrency
          )
        end

        def translate_strategy_repeat(conf)
          times = conf.delete(times)

          return translate_strategy_matrix(conf) if times.nil?

          cmd = translate_strategy_parallelism(times)
          cmd.concurrency = conf.delete('maxConcurrency')

          cmd
        end
      end
    end
  end
end
