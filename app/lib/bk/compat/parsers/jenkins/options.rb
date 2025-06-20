# frozen_string_literal: true

require_relative '../../models/steps/command'
require_relative '../../models/plugin'

module BK
  module Compat
    # Jenkins YAML converter
    class Jenkins
      # TODO: use an actual parser instead of regex
      OPT_REGEXP = /\A(?<option>\w+)\s*\((?<params>.*)\s*\)\Z/

      private

      def translate_options(options)
        return [] unless options.is_a?(Array)

        CommandStep.new(key: 'options').tap do |step|
          options.map do |option|
            step << parse_option(option)
          end
        end
      end

      def parse_option(option)
        match = OPT_REGEXP.match(option)

        param_data = match.named_captures.transform_values(&:strip)
        option = param_data.delete('option')
        resolver = "translate_option_#{option}"

        return "# Option element #{option} can not be translated (yet)" unless respond_to?(resolver, true)

        send(resolver, param_data)
      end

      def translate_option_buildDiscarder(params) # rubocop:disable Naming/MethodName
        num = params['params'].match(/numToKeepStr:\s*'(\d+)'/)&.[](1) || 'unknown'
        "# buildDiscarder: Build retention is managed through Buildkite's UI settings (set to keep #{num} builds)"
      end

      def translate_option_checkoutToSubdirectory(params) # rubocop:disable Naming/MethodName
        folder = params['params'].gsub(/['"()]/, '')
        CommandStep.new(
          key: 'checkout_to_subdirectory',
          env: {
            'BUILDKITE_BUILD_CHECKOUT_PATH' => "$$BUILDKITE_BUILD_PATH/#{folder}"
          }
        )
      end

      def translate_option_disableConcurrentBuilds(_params) # rubocop:disable Naming/MethodName
        '# disableConcurrentBuilds: Disabling concurrent builds is done through the pipeline settings in the UI'
      end

      def translate_option_disableRestartFromStage(_params) # rubocop:disable Naming/MethodName
        [
          '# disableRestartFromStage has no equivalent in Buildkite, you may be interested',
          '#   in setting "retry: { manual: false }" on the step to prevent retries'
        ]
      end

      def translate_option_disableResume(_params) # rubocop:disable Naming/MethodName
        '# disableResume has no equivalent in Buildkite'
      end

      def translate_option_newContainerPerStage(_params) # rubocop:disable Naming/MethodName
        '# newContainerPerStage: Different steps run in isolated environments by default'
      end

      def translate_option_overrideIndexTriggers(_params) # rubocop:disable Naming/MethodName
        [
          '# overrideIndexTriggers: what branches trigger a pipeline/step are handled in the pipeline',
          '#   settings or in the `if` property of steps'
        ]
      end

      def translate_option_parallelsAlwaysFailFast(_params) # rubocop:disable Naming/MethodName
        CommandStep.new(cancel_on_build_failing: true)
      end

      def translate_option_preserveStashes(_params) # rubocop:disable Naming/MethodName
        '# preserveStashes: Artifacts are kept by default and can not be changed through pipeline options'
      end

      def translate_option_quietPeriod(_params) # rubocop:disable Naming/MethodName
        '# quietPeriod has no equivalent in Buildkite'
      end

      def translate_option_retry(params)
        CommandStep.new(
          key: 'retries',
          retry: { automatic: { limit: params } }
        )
      end

      def translate_option_skipDefaultCheckout(_params) # rubocop:disable Naming/MethodName
        Plugin.new(
          name: 'cultureamp/skip-checkout-buildkite-plugin'
        )
      end

      def translate_option_skipStagesAfterUnstable(_params) # rubocop:disable Naming/MethodName
        [
          '# skipStagesAfterUnstable has no equivalent in Buildkite, but you may want',
          '#   to use the "cancel_on_build_failing" property on subsequent steps'
        ]
      end

      def translate_option_timeout(params)
        match = params['params'].match(/time:\s*(\d+),\s*unit:\s*["'](\w+)["']/)

        return unless match

        time = match[1].to_i
        unit = match[2].downcase

        multiplier = {
          seconds: 1 / 60,
          minutes: 1,
          hours: 60,
          days: 1440
        }
        minutes = time * multiplier.fetch(unit.to_sym, 1)

        CommandStep.new(key: 'timeout', timeout_in_minutes: minutes.ceil)
      end

      def translate_option_timestamps(_params)
        '# Timestamps are automatically shown in Buildkite logs and you can hide them in the UI'
      end
    end
  end
end
