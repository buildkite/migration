# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Handles the translation of slack notifications
      class Translator
        def translate_slack(inputs)
          warnings = generate_warnings(inputs)

          if error_config?(inputs)
            create_dual_notifications(inputs, warnings)
          else
            create_single_notification(inputs, warnings)
          end
        end

        private

        def error_config?(inputs)
          supported_error_keys = %w[channel_on_error text_on_error]
          inputs.keys.any? { |k| supported_error_keys.include?(k) && !inputs[k].to_s.empty? }
        end

        def generate_warnings(inputs)
          supported_options = %w[
            channel channel_on_error
            text text_on_error
          ]

          unsupported = inputs.keys.difference(supported_options)
          return nil if unsupported.empty?

          '# Warning: The following options are not supported in Buildkite and will be ignored: ' \
            "#{unsupported.join(', ')}"
        end

        def build_base_config(inputs)
          config = {
            'message' => inputs['text']
          }.compact

          config['channels'] = [inputs['channel']] if inputs['channel']

          config
        end

        def build_error_config(inputs)
          config = {
            'message' => inputs['text_on_error'] || inputs['text']
          }.compact

          if inputs['channel_on_error'] || inputs['channel']
            config['channels'] = [inputs['channel_on_error'] || inputs['channel']]
          end

          config
        end

        def create_single_notification(inputs, warnings)
          BK::Compat::CommandStep.new(
            notify: [{ 'slack' => build_base_config(inputs) }],
            commands: warnings.nil? ? nil : [warnings]
          )
        end

        def create_dual_notifications(inputs, warnings)
          step = create_single_notification(inputs, warnings)
          success_config = step.notify.first['slack'].merge('if' => 'build.state == "passed"')
          error_config = build_error_config(inputs)
                         .merge('if' => 'build.state == "failed"')
          step.notify = [
            { 'slack' => success_config },
            { 'slack' => error_config }
          ]

          step
        end
      end
    end
  end
end
